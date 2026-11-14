// Koru Backend (Pass 2) — thin driver; PROGRAM_AST lives in program_ast.zig
// This file IS the compiler backend - it generates final code at compile-time

const Program = @import("ast").Program;
const ast_json_mod = @import("ast_json");
fn maybeDeinitAst(_: *const Program) void {}

const emitter_helpers = @import("emitter_helpers");
const __koru_std = @import("std");
const log = @import("log");

// Compiler environment lives in the static compiler_env module — re-exported here so
// `@import("root").CompilerEnv` keeps working for existing consumers.
pub const CompilerEnv = @import("compiler_env").CompilerEnv;

// Metacircular Code Generator

const __koru_ast = @import("ast");
comptime { _ = @import("backend_output"); }

const KoruCoordinateResult = extern struct {
    is_error: bool,
    code_ptr: [*]const u8,
    code_len: usize,
    metrics_ptr: [*]const u8,
    metrics_len: usize,
    error_ptr: [*]const u8,
    error_len: usize,
};
extern fn koru_coordinate(
    program_ast: *const __koru_ast.Program,
    allocator: *const __koru_std.mem.Allocator,
) KoruCoordinateResult;

extern fn koru_command_dispatch(
    name: *const anyopaque, // *const []const u8
    program: *const __koru_ast.Program,
    allocator: *const __koru_std.mem.Allocator,
    argv: *const anyopaque, // *const []const []const u8 (Zig slice; cast on the other side)
) void;

extern fn koru_run_pass(
    annotation: *const anyopaque, // *const []const u8
    program: *const __koru_ast.Program,
    allocator: *const __koru_std.mem.Allocator,
    out_program: *?*const __koru_ast.Program,
    ctx: ?*anyopaque, // *CompilerContext, opaque across the unit boundary
) bool;

// Re-export transform dispatcher — Zig-side shim around the extern wrapper
// so existing callers in src/ see an unchanged calling convention.
pub fn process_all_transforms(
    annotation: []const u8,
    program: *const __koru_ast.Program,
    allocator: __koru_std.mem.Allocator,
    ctx: ?*anyopaque,
) !*const __koru_ast.Program {
    var out_program: ?*const __koru_ast.Program = null;
    const ok = koru_run_pass(@ptrCast(&annotation), program, &allocator, &out_program, ctx);
    if (!ok) return error.TransformFailed;
    return out_program orelse return error.TransformFailed;
}

// Helper: Join path segments with dots
const joinPath = struct {
    fn call(path: []const []const u8) []const u8 {
        if (path.len == 0) return "";
        if (path.len == 1) return path[0];
        var total_len: usize = path[0].len;
        var i: usize = 1;
        while (i < path.len) : (i += 1) {
            total_len += 1 + path[i].len;
        }
        var result: [256]u8 = undefined;
        var pos: usize = 0;
        @memcpy(result[pos..pos + path[0].len], path[0]);
        pos += path[0].len;
        i = 1;
        while (i < path.len) : (i += 1) {
            result[pos] = '.';
            pos += 1;
            @memcpy(result[pos..pos + path[i].len], path[i]);
            pos += path[i].len;
        }
        return result[0..pos];
    }
}.call;

// Runtime emitter - calls the coordinate event from compiler.kz
// The visitor emitter handles abstract/impl resolution automatically
const RuntimeEmitter = struct {
    pub fn emit(allocator: __koru_std.mem.Allocator, source_ast: *const Program) ![]const u8 {
        const result = koru_coordinate(source_ast, &allocator);
        if (result.is_error) {
            const e = result.error_ptr[0..result.error_len];
            // A REFUSAL IS NOT A CRASH. The coordinate flow has already reported its
            // diagnostic through the reporter by the time we reach here, so returning
            // an error out of main would make Zig print `error.CompilerCoordinationFailed`
            // plus a return trace naming THIS generated file — a crash report stapled to
            // a correct rejection, and the last thing the author reads. Exit
            // deliberately instead: the status is still non-zero, so koruc's
            // non-zero-exit path still runs the diagnostics summary and still
            // reports the failure. Nothing is swallowed; one misleading rendering of an
            // already-delivered diagnostic is dropped.
            //
            // The coordination echo itself is gated the same way: when the reporter
            // already rendered a diagnostic (`errors.diagnostics_were_printed`), the
            // error-string summary is a vaguer, location-free repeat of it — one
            // refusal, one message. When NO diagnostic was rendered the print stays:
            // a user-authored coordinator override's error string or a
            // diagnostic-free internal failure IS the message.
            const reporter_spoke = @import("errors").diagnostics_were_printed;
            if (!reporter_spoke) {
                __koru_std.debug.print("❌ Compiler coordination error: {s}\n", .{e});
            }
            // The trace stays REACHABLE on request, because for a genuine INTERNAL
            // failure it is the useful output, and suppressing it unconditionally would
            // trade this bug for its mirror — a compiler crash reported as a rejection,
            // which sends the author hunting through correct code. `is_error` is one
            // boolean carrying both meanings, so the choice belongs to whoever is
            // debugging rather than being guessed at here. A kind on the C-ABI result
            // would let the compiler decide for itself; that is the honest version and
            // it is not this change.
            const trace_requested: ?[]const u8 = __koru_std.process.getEnvVarOwned(allocator, "KORU_BACKEND_TRACE") catch null;
            defer if (trace_requested) |v| allocator.free(v);
            if (trace_requested != null) return error.CompilerCoordinationFailed;
            if (!reporter_spoke) {
                __koru_std.debug.print("   (set KORU_BACKEND_TRACE=1 for the backend return trace)\n", .{});
            }
            __koru_std.process.exit(1);
        }
        const metrics = result.metrics_ptr[0..result.metrics_len];
        const code = result.code_ptr[0..result.code_len];
        __koru_std.debug.print("🎯 Compiler coordination: {s}\n", .{metrics});
        return code;
    }
};
// AST Dump Helper - observability for compiler pipeline debugging
// Note: This version doesn't serialize to JSON (ast_serializer not available in backend.zig)
// Full JSON dumps are available in backend_output_emitted.zig (dump points 3-7)
fn dumpAST(program_ast: *const Program, stage: []const u8, allocator: __koru_std.mem.Allocator) void {
    // Check if AST dumping is enabled via environment variable
    const dump_enabled: ?[]const u8 = __koru_std.process.getEnvVarOwned(allocator, "KORU_DUMP_AST") catch |err| blk: {
        if (err == error.EnvironmentVariableNotFound) break :blk null;
        break :blk null;
    };
    defer if (dump_enabled) |val| allocator.free(val);

    if (dump_enabled == null) return;  // Not enabled

    __koru_std.debug.print("\n============================================================\n", .{});
    __koru_std.debug.print("AST DUMP: {s}\n", .{stage});
    __koru_std.debug.print("============================================================\n", .{});
    __koru_std.debug.print("Items: {d}\n", .{program_ast.items.len});
    __koru_std.debug.print("Module: {s}\n", .{program_ast.main_module_name});
    __koru_std.debug.print("============================================================\n\n", .{});
}
var koru_budget_mb: usize = 4096;
var koru_budget_fired: bool = false;

const BudgetAllocator = struct {
    child: __koru_std.mem.Allocator,

    fn alloc(ctx: *anyopaque, len: usize, alignment: __koru_std.mem.Alignment, ret_addr: usize) ?[*]u8 {
        const self: *BudgetAllocator = @ptrCast(@alignCast(ctx));
        const result = self.child.rawAlloc(len, alignment, ret_addr);
        if (result == null and !koru_budget_fired) {
            koru_budget_fired = true;
            __koru_std.debug.print("error[KORU174]: compilation exceeded its compile memory budget ({d} MB) — the compiler refused; nothing was miscompiled and nothing ran. Raise the budget with --compile-mem-mb=<mb> or KORU_COMPILE_MEM_MB.\n", .{koru_budget_mb});
            __koru_std.process.exit(1);
        }
        return result;
    }

    fn resize(ctx: *anyopaque, memory: []u8, alignment: __koru_std.mem.Alignment, new_len: usize, ret_addr: usize) bool {
        const self: *BudgetAllocator = @ptrCast(@alignCast(ctx));
        return self.child.rawResize(memory, alignment, new_len, ret_addr);
    }

    fn remap(ctx: *anyopaque, memory: []u8, alignment: __koru_std.mem.Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
        const self: *BudgetAllocator = @ptrCast(@alignCast(ctx));
        return self.child.rawRemap(memory, alignment, new_len, ret_addr);
    }

    fn free(ctx: *anyopaque, memory: []u8, alignment: __koru_std.mem.Alignment, ret_addr: usize) void {
        const self: *BudgetAllocator = @ptrCast(@alignCast(ctx));
        self.child.rawFree(memory, alignment, ret_addr);
    }

    fn allocator(self: *BudgetAllocator) __koru_std.mem.Allocator {
        return .{ .ptr = self, .vtable = &__koru_std.mem.Allocator.VTable{
            .alloc = alloc,
            .resize = resize,
            .remap = remap,
            .free = free,
        } };
    }
};
// === KORU BACKEND CODE GENERATOR ===
// This outputs the final Zig code generated by compiler.emit.zig

const errors_mod = @import("errors");

const DiagJsonlSink = struct {
    file: __koru_std.fs.File,
    allocator: __koru_std.mem.Allocator,

    fn emit(ctx: *anyopaque, err: *const errors_mod.ParseError) void {
        const self: *DiagJsonlSink = @ptrCast(@alignCast(ctx));
        var line = __koru_std.ArrayList(u8){};
        line.appendSlice(self.allocator, "{\"code\":\"") catch return;
        line.appendSlice(self.allocator, @tagName(err.code)) catch return;
        line.appendSlice(self.allocator, "\",\"file\":\"") catch return;
        diagJsonEscape(&line, self.allocator, err.location.file);
        const loc_num = __koru_std.fmt.allocPrint(self.allocator, "\",\"line\":{d},\"column\":{d},\"message\":\"", .{ err.location.line, err.location.column }) catch return;
        line.appendSlice(self.allocator, loc_num) catch return;
        diagJsonEscape(&line, self.allocator, err.message);
        line.append(self.allocator, '"') catch return;
        if (err.hint) |h| {
            line.appendSlice(self.allocator, ",\"hint\":\"") catch return;
            diagJsonEscape(&line, self.allocator, h);
            line.append(self.allocator, '"') catch return;
        }
        line.append(self.allocator, '}') catch return;
        line.append(self.allocator, '\n') catch return;
        self.file.writeAll(line.items) catch {};
    }
};

fn diagJsonEscape(out: *__koru_std.ArrayList(u8), alloc: __koru_std.mem.Allocator, s: []const u8) void {
    for (s) |c| {
        switch (c) {
            '"' => out.appendSlice(alloc, "\\\"") catch return,
            '\\' => out.appendSlice(alloc, "\\\\") catch return,
            '\n' => out.appendSlice(alloc, "\\n") catch return,
            '\r' => out.appendSlice(alloc, "\\r") catch return,
            '\t' => out.appendSlice(alloc, "\\t") catch return,
            else => {
                if (c < 0x20) {
                    const esc = __koru_std.fmt.allocPrint(alloc, "\\u{x:0>4}", .{c}) catch return;
                    out.appendSlice(alloc, esc) catch return;
                } else {
                    out.append(alloc, c) catch return;
                }
            },
        }
    }
}

// `std/compiler(diagnostic)` parses as a bare invocation on the
// std/compiler default door — segments ["std/compiler"] (or the
// qualified "std/compiler"/"std.compiler" + ["default"] spelling),
// first arg the literal word `diagnostic`.
fn isDiagJoinInvocation(inv: *const __koru_ast.Invocation) bool {
    const p = &inv.path;
    const on_door = if (p.module_qualifier) |mq|
        (__koru_std.mem.eql(u8, mq, "std/compiler") or __koru_std.mem.eql(u8, mq, "std.compiler")) and
            p.segments.len == 1 and __koru_std.mem.eql(u8, p.segments[0], "default")
    else
        p.segments.len == 1 and (__koru_std.mem.eql(u8, p.segments[0], "std/compiler") or
            __koru_std.mem.eql(u8, p.segments[0], "std.compiler"));
    if (!on_door) return false;
    return inv.args.len > 0 and __koru_std.mem.eql(u8, inv.args[0].value, "diagnostic");
}

fn diagArmSinkName(inv: *const __koru_ast.Invocation) []const u8 {
    if (inv.path.segments.len == 0) return "";
    return inv.path.segments[inv.path.segments.len - 1];
}

fn diagArgText(args: []const __koru_ast.Arg, want: []const u8) ?[]const u8 {
    for (args) |a| {
        if (__koru_std.mem.eql(u8, a.name, want)) {
            var v = a.value;
            if (v.len >= 2 and v[0] == '"' and v[v.len - 1] == '"') v = v[1 .. v.len - 1];
            return v;
        }
    }
    return null;
}

// `X:config { k: v }` — a module-targeted directive block, same family
// as `compiler:use` and `x:new`. The braces arrive as verbatim
// source in a `source` arg; the plugin owns the grammar inside —
// `key: literal` entries separated by newline or `,`. The pass
// claims the flow only when X's module actually carries a
// `std/compiler(diagnostic)` join; any other `X:config` stays in
// the tree and coordinate refuses it, so config on a non-plugin
// module is a compile error, not a silent no-op.
const DiagConfigEntry = struct { key: []const u8, value: []const u8 };

// A config qualifier names its plugin module by logical name —
// `koru/compiler/sqlite:config` and `koru.compiler.sqlite:config`
// both normalize to the decl's dotted `logical_name`.
fn diagConfigKeyMatches(qualifier: []const u8, logical_name: []const u8) bool {
    if (qualifier.len != logical_name.len) return false;
    for (qualifier, logical_name) |a, b| {
        if ((if (a == '/') '.' else a) != b) return false;
    }
    return true;
}

fn diagPluginNameFor(plugin_names: *__koru_std.StringHashMap(void), qualifier: []const u8) ?[]const u8 {
    var it = plugin_names.keyIterator();
    while (it.next()) |k| {
        if (diagConfigKeyMatches(qualifier, k.*)) return k.*;
    }
    return null;
}

fn diagConfigQualifier(f: *const __koru_ast.Flow) ?[]const u8 {
    if (f.body.node) |*n| {
        if (n.* != .invocation) return null;
        const inv = &n.invocation;
        const mq = inv.path.module_qualifier orelse return null;
        if (inv.path.segments.len != 1) return null;
        if (!__koru_std.mem.eql(u8, inv.path.segments[0], "config")) return null;
        return mq;
    }
    return null;
}

fn diagParseConfig(allocator: __koru_std.mem.Allocator, source: []const u8) __koru_std.ArrayList(DiagConfigEntry) {
    var out = __koru_std.ArrayList(DiagConfigEntry){};
    var start: usize = 0;
    var in_str = false;
    var i: usize = 0;
    while (i <= source.len) : (i += 1) {
        if (i < source.len and source[i] == '"' and (i == 0 or source[i - 1] != '\\')) in_str = !in_str;
        const at_sep = i == source.len or (!in_str and (source[i] == '\n' or source[i] == ','));
        if (!at_sep) continue;
        const chunk = __koru_std.mem.trim(u8, source[start..i], " \t\r");
        start = i + 1;
        if (chunk.len == 0) continue;
        const colon = __koru_std.mem.indexOfScalar(u8, chunk, ':') orelse {
            __koru_std.debug.print("⚠️  diagnostic config: '{s}' is not a 'key: value' entry — skipped\n", .{chunk});
            continue;
        };
        const key = __koru_std.mem.trim(u8, chunk[0..colon], " \t\r");
        var value = __koru_std.mem.trim(u8, chunk[colon + 1 ..], " \t\r");
        if (value.len >= 2 and value[0] == '"' and value[value.len - 1] == '"') value = value[1 .. value.len - 1];
        if (key.len == 0 or value.len == 0) continue;
        out.append(allocator, .{ .key = key, .value = value }) catch {};
    }
    return out;
}

fn diagConfigGet(entries: ?[]const DiagConfigEntry, key: []const u8) ?[]const u8 {
    const list = entries orelse return null;
    var found: ?[]const u8 = null;
    for (list) |e| {
        if (__koru_std.mem.eql(u8, e.key, key)) found = e.value;
    }
    return found;
}

fn diagItemsContainJoin(items: []const __koru_ast.Item) bool {
    for (items) |*item| {
        switch (item.*) {
            .flow => |*f| {
                if (f.body.node) |*n| {
                    if (n.* == .invocation and isDiagJoinInvocation(&n.invocation)) return true;
                }
            },
            .module_decl => |*md| {
                if (diagItemsContainJoin(md.items)) return true;
            },
            else => {},
        }
    }
    return false;
}

fn findDiagPluginModules(items: []const __koru_ast.Item, out: *__koru_std.StringHashMap(void)) void {
    for (items) |*item| {
        switch (item.*) {
            .module_decl => |*md| {
                if (diagItemsContainJoin(md.items)) out.put(md.logical_name, {}) catch {};
                findDiagPluginModules(md.items, out);
            },
            else => {},
        }
    }
}

fn collectDiagConfigFlows(allocator: __koru_std.mem.Allocator, items: []const __koru_ast.Item, plugin_names: *__koru_std.StringHashMap(void), configs: *__koru_std.StringHashMap(__koru_std.ArrayList(DiagConfigEntry))) void {
    for (items) |*item| {
        switch (item.*) {
            .flow => |*f| {
                const mq = diagConfigQualifier(f) orelse continue;
                const key = diagPluginNameFor(plugin_names, mq) orelse continue;
                const src = diagArgText(f.body.node.?.invocation.args, "source") orelse "";
                configs.put(key, diagParseConfig(allocator, src)) catch {};
            },
            .module_decl => |*md| collectDiagConfigFlows(allocator, md.items, plugin_names, configs),
            else => {},
        }
    }
}

// One `!` arm = one consumer. Stage-0 semantics: the arm's tor name
// resolves against builtin sinks — the Koru spelling is the contract,
// the builtin is the implementation (arbitrary user-authored sink
// bodies need the interpreter; that is a later conversation). Sink
// parameters come from the declaring module's `X:config` entries
// (cfg) with per-site arm args winning over module-level keys.
fn registerDiagArms(allocator: __koru_std.mem.Allocator, join_flow: *const __koru_ast.Flow, cfg: ?[]const DiagConfigEntry) void {
    for (join_flow.body.continuations) |*cont| {
        const step = cont.node orelse continue;
        if (step != .invocation) continue;
        const name = diagArmSinkName(&step.invocation);
        if (__koru_std.mem.eql(u8, name, "jsonl")) {
            const path = diagArgText(step.invocation.args, "path") orelse (diagConfigGet(cfg, "file") orelse "koru-diagnostics.jsonl");
            const file = __koru_std.fs.cwd().createFile(path, .{}) catch |err| {
                __koru_std.debug.print("⚠️  diagnostic sink: cannot open '{s}': {s}\n", .{ path, @errorName(err) });
                continue;
            };
            const sink = allocator.create(DiagJsonlSink) catch continue;
            sink.* = .{ .file = file, .allocator = allocator };
            errors_mod.registerDiagSink(allocator, .{ .ctx = sink, .emit = DiagJsonlSink.emit }) catch {};        } else {
            __koru_std.debug.print("⚠️  diagnostic sink '{s}' is not a builtin — arm ignored\n", .{name});
        }
    }
}

fn filterDiagJoinItems(allocator: __koru_std.mem.Allocator, items: []const __koru_ast.Item, mod_name: ?[]const u8, plugin_names: *__koru_std.StringHashMap(void), configs: *__koru_std.StringHashMap(__koru_std.ArrayList(DiagConfigEntry))) []const __koru_ast.Item {
    var kept = __koru_std.ArrayList(__koru_ast.Item){};
    for (items) |*item| {
        switch (item.*) {
            .flow => |*f| {
                var is_join = false;
                if (f.body.node) |*n| {
                    if (n.* == .invocation and isDiagJoinInvocation(&n.invocation)) is_join = true;
                }
                if (is_join) {
                    const cfg: ?[]const DiagConfigEntry = if (mod_name) |mn|
                        (if (configs.get(mn)) |c| c.items else null)
                    else
                        null;
                    registerDiagArms(allocator, f, cfg);
                    continue;
                }
                if (diagConfigQualifier(f)) |mq| {
                    if (diagPluginNameFor(plugin_names, mq) != null) continue;
                }
                kept.append(allocator, item.*) catch {};
            },
            .module_decl => |*md| {
                const mutable = @constCast(md);
                mutable.items = filterDiagJoinItems(allocator, md.items, md.logical_name, plugin_names, configs);
                kept.append(allocator, item.*) catch {};
            },
            else => kept.append(allocator, item.*) catch {},
        }
    }
    return kept.items;
}

fn collectDiagJoins(allocator: __koru_std.mem.Allocator, prog: *Program) *const Program {
    var plugin_names = __koru_std.StringHashMap(void).init(allocator);
    findDiagPluginModules(prog.items, &plugin_names);
    var configs = __koru_std.StringHashMap(__koru_std.ArrayList(DiagConfigEntry)).init(allocator);
    collectDiagConfigFlows(allocator, prog.items, &plugin_names, &configs);
    prog.items = filterDiagJoinItems(allocator, prog.items, null, &plugin_names, &configs);
    return prog;
}
pub fn main() !void {
    // Compiler environment: per-invocation flags/lang/paths from
    // `compiler_env.json` (written beside this backend by the frontend).
    // Same channel as program.ast.json — nothing per-invocation is baked
    // into this binary, so one backend serves every flag combination.
    // Must load before ANY CompilerEnv read below (budget block first).
    CompilerEnv.load() catch |err| {
        __koru_std.debug.print("❌ Backend: cannot load compiler_env.json: {s}\n", .{@errorName(err)});
        return err;
    };
    // Budget: --compile-mem-mb=<mb> flag wins, then KORU_COMPILE_MEM_MB,
    // else 4096 MB. The flag is read per-invocation from CompilerEnv.flags,
    // so a regression test can pin a tiny budget without touching env.
    koru_budget_mb = blk: {
        // koruc bakes flags WITHOUT the leading dashes (`compile-mem-mb=8`);
        // match both spellings so a hand-run backend sees the same budget.
        const flag_pfx = "compile-mem-mb=";
        for (CompilerEnv.flags) |f| {
            const bare = if (__koru_std.mem.startsWith(u8, f, "--"))
                f[2..]
            else
                f;
            if (__koru_std.mem.startsWith(u8, bare, flag_pfx)) {
                if (__koru_std.fmt.parseInt(usize, bare[flag_pfx.len..], 10)) |v| {
                    if (v >= 1) break :blk v;
                } else |_| {}
            }
        }
        if (__koru_std.process.getEnvVarOwned(__koru_std.heap.page_allocator, "KORU_COMPILE_MEM_MB")) |v| {
            defer __koru_std.heap.page_allocator.free(v);
            if (__koru_std.fmt.parseInt(usize, v, 10)) |parsed| {
                if (parsed >= 1) break :blk parsed;
            } else |_| {}
        } else |_| {}
        break :blk 4096;
    };
    var gpa = __koru_std.heap.GeneralPurposeAllocator(.{
        .enable_memory_limit = true,
    }){};
    // The ceiling itself is a plain field (settable post-construction),
    // not a Config field — Config carries only the enable flag.
    gpa.requested_memory_limit = koru_budget_mb * 1024 * 1024;
    defer {
        const leak_status = gpa.deinit();
        if (leak_status == .leak) {
            __koru_std.debug.print("Memory leak detected\n", .{});
        }
    }
    var budget = BudgetAllocator{ .child = gpa.allocator() };
    const allocator = budget.allocator();

    // Arena allocator for compilation phase - all compiler passes, code generation, etc.
    var compile_arena = __koru_std.heap.ArenaAllocator.init(allocator);
    defer compile_arena.deinit();
    const compile_allocator = compile_arena.allocator();

    // argv carries the -o name (consumed by the in-pipeline
    // host-build steps via emitter_helpers.outputExeName) and any
    // command name for the dispatch below.
    const args = try __koru_std.process.argsAlloc(allocator);
    defer __koru_std.process.argsFree(allocator, args);
    const seed_ast: *Program = blk: {
        const ast_file = __koru_std.fs.cwd().openFile("program.ast.json", .{}) catch |err| {
            __koru_std.debug.print("❌ Backend: cannot open program.ast.json: {s}\n", .{@errorName(err)});
            return err;
        };
        defer ast_file.close();
        const ast_json_bytes = try ast_file.readToEndAlloc(compile_allocator, 256 * 1024 * 1024);
        const p = try compile_allocator.create(Program);
        p.* = try ast_json_mod.deserialize(compile_allocator, ast_json_bytes);
        break :blk p;
    };
    // Check for CLI commands in argv
    // Note: backend_output is already imported at file scope
    if (args.len > 1) {
        if (__koru_std.mem.eql(u8, args[1], "deps")) {
            __koru_std.debug.print("🔧 Running command: deps\n", .{});
            const cmd_name: []const u8 = "deps";
            const argv_slice: []const []const u8 = args[2..];
            koru_command_dispatch(@ptrCast(&cmd_name), seed_ast, &allocator, @ptrCast(&argv_slice));
            return;
        }
        if (__koru_std.mem.eql(u8, args[1], "claims")) {
            __koru_std.debug.print("🔧 Running command: claims\n", .{});
            const cmd_name: []const u8 = "claims";
            const argv_slice: []const []const u8 = args[2..];
            koru_command_dispatch(@ptrCast(&cmd_name), seed_ast, &allocator, @ptrCast(&argv_slice));
            return;
        }
        if (__koru_std.mem.eql(u8, args[1], "assumes")) {
            __koru_std.debug.print("🔧 Running command: assumes\n", .{});
            const cmd_name: []const u8 = "assumes";
            const argv_slice: []const []const u8 = args[2..];
            koru_command_dispatch(@ptrCast(&cmd_name), seed_ast, &allocator, @ptrCast(&argv_slice));
            return;
        }
    }
    // Apply compiler passes
    // Each pass takes PROGRAM_AST pointer and current AST pointer
    // Returns same pointer if no changes, or new heap-allocated AST if optimized
    const current_ast: *const Program = collectDiagJoins(compile_allocator, seed_ast);
    defer errors_mod.finishDiagSinks();

    // DUMP POINT 1: Original AST at backend entry
    dumpAST(seed_ast, "1-backend-start", compile_allocator);

    // More passes can go here...

    const final_ast = current_ast;
    defer maybeDeinitAst(final_ast);

    // DUMP POINT 2: Final AST before emission (after all backend transforms)
    dumpAST(final_ast, "2-pre-emit", compile_allocator);

    // The pipeline owns materialization now: emission's
    // per-target arms (emit-*-artifact) write the artifact,
    // validate it under --deep-check, and run Stage D. The
    // driver's only job post-coordinate is the metrics line
    // RuntimeEmitter.emit already printed.
    _ = try RuntimeEmitter.emit(compile_allocator, final_ast);
}