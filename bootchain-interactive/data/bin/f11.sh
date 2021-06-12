#!/bin/bash -efu

cmd='dialog --backtitle "Welcome to ALT!" --title "[ Calcualating... ]" --gauge "\nHow many times I see it..." 7 40'
echo 0 |eval "$cmd"
cmd='dialog --keep-window --backtitle "Welcome to ALT!" --title "[ Calcualating... ]" --gauge "\nHow many times I see it..." 7 40'

for j in $(seq 1 10); do
	for i in $(seq 0 10); do
		echo "${i}0" |eval "$cmd"
		sleep 0.1
	done
	for i in $(seq 0 10 |sort -nr); do
		echo "${i}0" |eval "$cmd"
		sleep 0.1
	done
done
