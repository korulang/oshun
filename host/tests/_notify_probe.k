import libs/host
import std/build
import std/io

std/build:app { name: "Notify Probe", id: "org.koru.oshun.notifyprobe", version: "0.1" }

[with(libs/host)]
notify.send(title: "◉ probe", body: "direct call")
| ok |> std/io:print.ln("notify: sent")
| err e |> std/io:print.ln("notify: {{ e:s }}")
