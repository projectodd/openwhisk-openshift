#!/usr/bin/env bash

### Output some basic stats for recent function activations

set -e

func=$1
count=$2

if [ "${func}x" = "x" ]; then
  echo "You must supply a function as the first argument"
  exit 1
fi

if [ "${count}x" = "x" ]; then
    echo "No count provided as second argument - defaulting to 200"
    count=200
fi

dir=".stats_output/$func"
mkdir -p $dir
rm -rf $dir/*

echo "Gathering stats for last $count executions of $func"
echo ""

step=200
for skip in {0..10000..200}; do
  if [[ $skip -ge $count ]]; then
    break
  fi
  limit=$(($skip + $step > $count ? $count - $skip : $step))
  wsk activation list $func -l $limit -s $skip -f | grep '"end":' | awk '{print $2}' | tr -d "," >> $dir/throughput
  wsk activation list $func -l $limit -s $skip -f | grep -A 1 '"waitTime"' | grep value | awk '{print $2}' >> $dir/waitTime
done

### Throughput
file="$dir/throughput"
first=$(sort -n $file | head -n 1)
last=$(sort -n $file | tail -n 1)
count=$(wc -l $file | awk '{print $1}')

duration=$(echo "scale=2; ($last - $first) / 1000" | bc)
throughput=$(echo "scale=2; $count / $duration" | bc)
echo "Duration: ${duration}s"
echo "Count: $count"
echo "Throughput: $throughput per second"
echo ""

### Wait Time
file="$dir/waitTime"
p95=$(sort -n $file | awk '{all[NR] = $0} END{print all[int(NR*0.95 - 0.5)]}')
p90=$(sort -n $file | awk '{all[NR] = $0} END{print all[int(NR*0.90 - 0.5)]}')
p75=$(sort -n $file | awk '{all[NR] = $0} END{print all[int(NR*0.75 - 0.5)]}')
p50=$(sort -n $file | awk '{all[NR] = $0} END{print all[int(NR*0.50 - 0.5)]}')

echo "Wait time percentiles:"
echo "95th: ${p95}ms"
echo "90th: ${p90}ms"
echo "75th: ${p75}ms"
echo "50th: ${p50}ms"
