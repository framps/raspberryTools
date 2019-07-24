#!/bin/bash
#
# Retrieve throttling bits of Raspberry and report their meaning
#
# Copyright (C) 2019 framp at linux-tips-and-tricks dot de
#
# Meaning according https://github.com/raspberrypi/documentation/blob/JamesH65-patch-vcgencmd-vcdbg-docs/raspbian/applications/vcgencmd.md
# 0-

m=( "Under-voltage detected" "Arm frequency capped" "Currently throttled" "Soft temperature limit active" \
""  ""  ""  ""  ""  ""  ""  ""  ""  ""  ""  "" \
"Under-voltage has occurred" "Arm frequency capped has occurred" "Throttling has occurred" "Soft temperature limit has occurred" )

function analyze() {
	b=$(perl -e "printf \"%08b\\n\", $1" 2>/dev/null)
	i=0
	while [[ -n $b ]]; do
		t=${b:${#b}-1:1}
		if (( $t != 0 )); then
			if (( $i <= ${#m[@]} - 1 )) && [[ -n ${m[$i]} ]]; then
				echo "Bit $i set: ${m[$i]}"
			elif [[ -z ${m[$i]} ]] || (( $i > ${#m[@]} - 1 )); then
				echo "Bit $i set: meaning unknown"
			fi
		fi
		b=${b::-1}
		(( i++ ))
	done
}

t=$(vcgencmd get_throttled | cut -f 2 -d "=" )
echo "Throttling in hex ('occured' bits reset on boot only): $t"
analyze $t

t=$(vcgencmd get_throttled 0xf | cut -f 2 -d "=" )
echo "Throttling in hex: $t ('occured' bits reset after call)"
analyze $t
