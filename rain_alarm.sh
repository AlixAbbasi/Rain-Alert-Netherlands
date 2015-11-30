#!/bin/bash
# Time to look ahead for expected rain.
DURATION=25

if [ -n "$1" ]; then
	HOUR="$1"
	MINUTE="$2"
	#DURATION="$3"
else
	# Get the current time, rounded above to the nearest 5 minutes
	HOUR="$(date +%H)"
	MINUTE="$(date +%M)"
	MINUTE=$((10#$MINUTE+5-10#$MINUTE%5)) # Read the number as base 10, not as an octal number (in the case of 09).
fi

# Fetch the forecast
RAIN_DATA=$(wget -O - 'http://gps.buienradar.nl/getrr.php?lat=52.24&lon=6.85' 2>/dev/null|awk -F'|' '{ printf("%3i %s\n", 10^(($1 -109)/32)*100, $2) }')
echo "$RAIN_DATA"

# Check per 5 minutes if there is rain expected.
for (( i=0;  $i < $((DURATION/5)); i++ )); do
	# Make sure we're have a properly formatted time, e.g., 8:05
	if [ $MINUTE -ge 60 ]; then
		MINUTE=0
		HOUR=$(((HOUR + 1)%24))
	fi
	if [ $MINUTE -lt 10 ]; then
		MINUTE="0$MINUTE"
	fi

	# Get the future forecast for the right time
	RAIN_TIME=$(echo "$RAIN_DATA"|grep "$HOUR:$MINUTE")
	EXPECTED_RAIN=$(echo $RAIN_TIME|awk '{ print $1 }')
	if [ ${EXPECTED_RAIN}0 -gt 0 ]; then # Hack: LHS is always a decimal number, equation is valid.
		echo -e "Expected rain: \033[1;31m$EXPECTED_RAIN\033[0m mm/hour at \033[0;31m$HOUR:$MINUTE\033[0m."
		if [ $i -eq 0 ]; then
			MESSAGE="Expected rain: $EXPECTED_RAIN millimeter per hour."
		else
			MESSAGE="Expected rain: $EXPECTED_RAIN millimeter per hour in $((5*i)) minutes."
		fi
		break
	fi

	MINUTE=$((MINUTE + 5))
done
if [ -x /usr/bin/spd-say ]; then
	if [ -n "$MESSAGE" ]; then
		/usr/bin/spd-say -t female2 -P important "$MESSAGE"
	else
		/usr/bin/spd-say -t female2 "No rain expected."
	fi
fi
