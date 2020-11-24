## output of report is a markdown like this:
## 
## # Benchmark results
## ...
## ## Addition {task}
## ### parameters: large1 + large2  {par}
## | |cpuTimes|CI(lower)|CI(upper)|
## |benchmark|1.2|1.0|1.4|  
## |benchmark_othersetting|1.5|1.2|1.7|
## ... {row is file}
import os, json, tables, strformat
from criterion/exporter import ParamTuple  # BenchmarkResult is not what is exported
from criterion/statistics import Estimates, CI
#[ this is the way it is exported
proc `%`(r: BenchmarkResult): JsonNode =
  %*{ "label": r.label
    , "parameters": r.params
    , "raw_data":
      { "iterations":   r.stats.iterations
      , "time":  r.stats.samples
      , "cycles": r.stats.cycleSamples
      }
    , "estimates":
      { "time": r.stats.samplesEst
      , "cycles": r.stats.cycleSamplesEst
      }
    }

]#
type
  BenchmarkResultExported = tuple
    label: string
    parameters: seq[ParamTuple] # not params
    # following two non existing in original BenchmarkResult
    raw_data: tuple[iterations: seq[int]; time, cycles: seq[float64]]
    estimates: tuple[time, cycles: Estimates]

proc parseBenchmarkResults(path: string): seq[BenchmarkResultExported] =
  for singleResult in path.readFile.parseJson:
    result.add singleResult.to(BenchmarkResultExported)

# types needed to implement the report structure (Task -> parameter -> table of results)
type
  BenchmarkRow = object
    name: string  # file
    cpuTimes, ciLower, ciUpper: float
  BenchmarkByPar = OrderedTableRef[string, seq[BenchmarkRow]]
  BenchmarkByTask = OrderedTable[string, BenchmarkByPar]

func par(r: BenchmarkResultExported): string =
  for parTuple in r.parameters:
    # I have a specific (unused) parameter for the name of parameters (bigints do not print well)
    if parTuple.name == "name":
      return parTuple.value

func row(r: BenchmarkResultExported, file: string): BenchmarkRow =
  BenchmarkRow(name: file,
               cpuTimes: r.estimates.time.mean.value,
               ciLower: r.estimates.time.mean.lower,
               ciUpper: r.estimates.time.mean.upper)

proc add(t: var BenchmarkByTask, r: BenchmarkResultExported, file: string) =
  let
    task = r.label
    par = r.par
    row = r.row file
  if task notin t:
    t[task] = {par: @[row]}.newOrderedTable
    return
  if par notin t[task]:
    t[task][par] = @[row]
    return
  t[task][par].add row

proc readBenchmarkByTask(files: seq[string]): BenchmarkByTask =
  for file in files:
    let bs = parseBenchmarkResults(file)
    for b in bs:
      result.add b, file

func render(t: seq[BenchmarkRow]): string =
  result = "| |cpuTimes|CI(lower)|CI(upper)|\n|---|---|---|---|\n"
  for row in t:
    result.add &"|{row.name}|{row.cpuTimes:.1f}|{row.ciLower:.1f}|{row.ciUpper:.1f}|\n"

func render(t: BenchmarkByTask): string =
  result = "# Benchmark results\n"
  for task in t.keys:
    result.add &"## {task}\n"
    for par in t[task].keys:
      result.add &"### {par}\n"
      result.add t[task][par].render

when isMainModule:
  let
    args = commandLineParams()  # should be a list of json file with Benchmark results: last file is output
  if args.len == 0:
    echo "1 argument: parseJson of given file\n:>1 arg: pars jsons and use last arg as output file for report"
  elif args.len == 1:
    echo args[0].parseBenchmarkResults
  else:
    let
      files = args[0 ..< ^1]
      output = args[^1]
    output.writeFile files.readBenchmarkByTask.render
