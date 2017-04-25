#!/bin/sh

array_to_json () {
	ARRAY=$1

	indirect_array_length $ARRAY
	len=$?
	result=""

	for (( li=0; li<${len}; li++ ));
	do
		element="$ARRAY[$li]"
		KEY="${!element%%:*}"
    	VALUE="${!element#*:}"
		
		result="$result,\"$KEY\":$VALUE"
	done

	echo "{${result:1}}"
}

indirect_array_length () {
	ARRAY=$1

	tmp="$ARRAY[@]"
	len=0

	for item in "${!tmp}"
	do
		len=`expr $len + 1`
	done

	return $len
}

get_index_by_key () {
	ARRAY=$1
	CHECK_KEY=$2

	indirect_array_length $ARRAY
	len=$?

	for (( li=0; li<${len}; li++ ));
	do
		element="$ARRAY[$li]"
		KEY="${!element%%:*}"
    	VALUE="${!element#*:}"
		
		if [ "$KEY" = "$CHECK_KEY" ]; then
			return $li
		fi
	done

	return -1
}

update_value_with_key () {
	ARRAY=$1
	CHECK_KEY=$2
	VALUE=$3

	indirect_array_length $ARRAY
	len=$?

	for (( li=0; li<${len}; li++ ));
	do
		element="$ARRAY[$li]"
		KEY="${!element%%:*}"

		if [ "$KEY" = "$CHECK_KEY" ]; then
			eval "$ARRAY[$li]=\"$CHECK_KEY:$VALUE\""
		fi
	done
}

add_element_to_array () {
	ARRAY=$1
	KEY=$2
	VALUE=$3

	indirect_array_length $ARRAY
	len=$?
	
	eval "$ARRAY[$len]=\"$KEY:$VALUE\""
}

change_array_to_dict_with_init_value () {
	ARRAY=$1
	VALUE=$2

	indirect_array_length $ARRAY
	len=$?

	for (( li=0; li<${len}; li++ ));
	do
		element="$ARRAY[$li]"
		KEY="${!element}"

		eval "$ARRAY[$li]=\"$KEY:$VALUE\""
	done
}

parse_int () {
	return `expr $1 + 0`
}

page=1
count=0
offset="START"

option=$1

if [ "$option" = "all" ]; then
	echo "Getting device info..."

	curl "https://api.airtable.com/v0/appUM5HKj3inWajQG/Device?view=Main%20View&fields%5B%5D=Name" \
	-H "Authorization: Bearer keyxNf62XhQELuU9x" > device.json

	# Construct a {id: device name} map json file
	jq -c '[foreach .records[] as $d ({}; setpath([$d.id]; $d.fields.Name))] | .[length-1]' device.json > device_map.json

	# Construct a {device name: count} array for later use.
	allDevice=`jq -r 'join("|")' device_map.json`
	IFS='|' read -r -a deviceArray <<< "$allDevice"
	change_array_to_dict_with_init_value deviceArray "0"
	add_element_to_array deviceArray "All" "0"

	# Loop all pages on Airtable
	while [ ! "$offset" = "null" ]
	do
		echo "Loading template page $page."

		# Query parameter to Airtable
		offsetQuery="pageSize=100&view=Approved"

		# Specify offset if any
		if [ ! "$offset" = "null" ] && [ $page -gt 1 ]; then
			offsetQuery="$offsetQuery&offset=$offset"
		fi

		queryURL="https://api.airtable.com/v0/appUM5HKj3inWajQG/Web%20Template%20Submission?$offsetQuery"

		echo "Get Request: $queryURL"

		# Download result json to dump.json
		curl "$queryURL" \
		-H "Authorization: Bearer keyxNf62XhQELuU9x" > dump.json

		# Get next page offset by Airtable
		# null will be returned if no more page.
		offset=`jq -r '.offset' dump.json`

		# Get template count
		size=`jq '.records | length' dump.json`
		i=0

		# Loop template array
		while [ $i -lt $size ]
		do
			# Increment "All" count in device array
			get_index_by_key deviceArray "All"
			idx=$?
			p="deviceArray[$idx]"
			oldAllCount="${!p#*:}"
			newAllCount=`expr $oldAllCount + 1`
			update_value_with_key deviceArray "All" "$newAllCount"

			# Map device id to device type
			tmpd=`jq -r --arg i $i '.records[$i | tonumber].fields.Device | join("|")' dump.json`
			IFS='|' read -r -a recordDevices <<< "$tmpd"

			# Loop all device type in this record and increment device count
			for deviceId in ${recordDevices[@]}
			do
				deviceType=`jq -r ".$deviceId" device_map.json`
				get_index_by_key deviceArray "$deviceType"
				idx=$?
				p="deviceArray[$idx]"
				oldCount="${!p#*:}"
				newCount=`expr $oldCount + 1`
				update_value_with_key deviceArray "$deviceType" "$newCount"
			done

			# Slugify template name, to be used in permalink
			templateSlug=`jq -r --arg i $i '.records[$i | tonumber].fields.Name' dump.json | awk '{$1=$1};1' | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z`

			# Template json object
		    templateJson=`jq --arg i $i --arg slug $templateSlug '{r: .records[$i | tonumber], s: $slug, host: .records[$i | tonumber].fields.URL | match("^http[s]?://([^/]*)")}' dump.json`

		    # Compile template with template json, try -P without pre document space
		    pug -o ../template -O "$templateJson" page-content-template.pug

		    # Rename to slug name
		    mv ../template/page-content-template.html "../template/$templateSlug.html"

		    # Handle next template
		    i=`expr $i + 1`
		    count=`expr $count + 1`

		    echo "T.$count: $templateSlug.html is generated!"
		done

		# Handle next page
		page=`expr $page + 1`

	done

	# Convert device count array to json string
	countJson=`array_to_json deviceArray`
	echo "$countJson"

	# Generate menu template
	pug -o ../template -O "$countJson" -P menu-count.pug

	# Rename to slug name
	mv ../template/menu-count.html "../_includes/menu.html"

	echo "Site left menu is updated!"

elif [ "$option" = "name" ]; then
	echo "Loading template with name \"$2\"."

	queryURL="https://api.airtable.com/v0/appUM5HKj3inWajQG/Web%20Template%20Submission"

	# Download result json to dump.json
	curl "$queryURL" \
	-G \
	--data-urlencode "pageSize=100" \
	--data-urlencode "view=Approved" \
	--data-urlencode "filterByFormula=FIND(LOWER(\"$2\"),LOWER({NAME}))!=0" \
	-H "Authorization: Bearer keyxNf62XhQELuU9x" > dump.json

	# Get template count
	size=`jq '.records | length' dump.json`
	i=0

	# Loop template array
	while [ $i -lt $size ]
	do
		# Slugify template name, to be used in permalink
		templateSlug=`jq -r --arg i $i '.records[$i | tonumber].fields.Name' dump.json | awk '{$1=$1};1' | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z`

		# Template json object
	    templateJson=`jq --arg i $i --arg slug $templateSlug '{r: .records[$i | tonumber], s: $slug, host: .records[$i | tonumber].fields.URL | match("^http[s]?://([^/]*)")}' dump.json`

	    # Compile template with template json, try -P without pre document space
	    pug -o ../template -O "$templateJson" page-content-template.pug

	    # Rename to slug name
	    mv ../template/page-content-template.html "../template/$templateSlug.html"

	    # Handle next template
	    i=`expr $i + 1`
	    count=`expr $count + 1`

	    echo "T.$count: $templateSlug.html is generated!"
	done
elif [ "$option" = "view" ]; then
	# Loop all pages on Airtable
	while [ ! "$offset" = "null" ]
	do
		echo "Loading template page $page in view: $2."

		# Query parameter to Airtable
		offsetQuery="pageSize=100&view=$2"

		# Specify offset if any
		if [ ! "$offset" = "null" ] && [ $page -gt 1 ]; then
			offsetQuery="$offsetQuery&offset=$offset"
		fi

		queryURL="https://api.airtable.com/v0/appUM5HKj3inWajQG/Web%20Template%20Submission?$offsetQuery"

		echo "Get Request: $queryURL"

		# Download result json to dump.json
		curl "$queryURL" \
		-H "Authorization: Bearer keyxNf62XhQELuU9x" > dump.json

		# Get next page offset by Airtable
		# null will be returned if no more page.
		offset=`jq -r '.offset' dump.json`

		# Get template count
		size=`jq '.records | length' dump.json`
		i=0

		# Loop template array
		while [ $i -lt $size ]
		do
			# Slugify template name, to be used in permalink
			templateSlug=`jq -r --arg i $i '.records[$i | tonumber].fields.Name' dump.json | awk '{$1=$1};1' | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z`

			# Template json object
		    templateJson=`jq --arg i $i --arg slug $templateSlug '{r: .records[$i | tonumber], s: $slug, host: .records[$i | tonumber].fields.URL | match("^http[s]?://([^/]*)")}' dump.json`

		    # Compile template with template json, try -P without pre document space
		    pug -o ../template -O "$templateJson" page-content-template.pug

		    # Rename to slug name
		    mv ../template/page-content-template.html "../template/$templateSlug.html"

		    # Handle next template
		    i=`expr $i + 1`
		    count=`expr $count + 1`

		    echo "T.$count: $templateSlug.html is generated!"
		done

		# Handle next page
		page=`expr $page + 1`

	done
fi

# if [ "$option" = "count" -o "$option" = "all" ];  then
# 	echo "Updating menu..."

# 	curl "https://api.airtable.com/v0/appUM5HKj3inWajQG/Device?view=Main%20View&fields%5B%5D=Name&fields%5B%5D=Template%20Count" \
# 	-H "Authorization: Bearer keyxNf62XhQELuU9x" > dump.json

# 	countJson=`jq -c '[foreach .records[] as $item ({}; setpath([ $item.fields.Name]; $item.fields["Template Count"])  | setpath(["All"]; .All + $item.fields["Template Count"]); .)] | .[length-1]' dump.json`

# 	echo "$countJson"

# 	pug -o ../template -O "$countJson" -P menu-count.pug

# 	# Rename to slug name
# 	mv ../template/menu-count.html "../_includes/menu.html"

# 	echo "Site left menu is updated!"
# fi


echo "Done."
