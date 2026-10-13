#!/usr/bin/env bash
nvidia-smi --query-gpu=temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null |
awk -F',' '
NR==1 {
  temp=$1; used=$2; total=$3
  gsub(/[[:space:]]/, "", temp)
  gsub(/[[:space:]]/, "", used)
  gsub(/[[:space:]]/, "", total)
  if (temp=="" || used=="" || total=="") next
  color="#9ece6a"
  if (temp+0 >= 80) color="#f7768e"
  else if (temp+0 >= 70) color="#e0af68"
  printf "%%{F%s}GPU %s°C%%{F-}  %%{F#7dcfff}VRAM %.1f/%.1fG%%{F-}\n", color, temp, used/1024, total/1024
  found=1
  exit
}
END { if (!found) print "GPU N/A  VRAM N/A" }
'
