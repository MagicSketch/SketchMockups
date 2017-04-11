#!/bin/sh

page=1
count=0
offset="START"

option=$1

if [ "$option" = "all" ]; then
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
fi

if [ "$option" = "count" -o "$option" = "all" ];  then
	echo "Updating menu..."

	curl "https://api.airtable.com/v0/appUM5HKj3inWajQG/Device?view=Main%20View&fields%5B%5D=Name&fields%5B%5D=Template%20Count" \
	-H "Authorization: Bearer keyxNf62XhQELuU9x" > dump.json

	countJson=`jq -c '[foreach .records[] as $item ({}; setpath([ $item.fields.Name]; $item.fields["Template Count"])  | setpath(["All"]; .All + $item.fields["Template Count"]); .)] | .[length-1]' dump.json`

	echo "$countJson"

	pug -o ../template -O "$countJson" -P menu-count.pug

	# Rename to slug name
	mv ../template/menu-count.html "../_includes/menu.html"

	echo "Site left menu is updated!"
fi


echo "Done."
