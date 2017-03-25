#!/bin/sh

page=1
count=0
offset="START"

# Loop all pages on Airtable
while [ ! "$offset" = "null" ]
do
	echo "Loading template page $page."

	# Query parameter to Airtable
	offsetQuery="pageSize=100&view=Main%20View"

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
		templateSlug=`jq -r --arg i $i '.records[$i | tonumber].fields.Name' dump.json | sed -e 's/[^[:alnum:]]/-/g' | tr -s '-' | tr A-Z a-z`

		# Template json object
	    templateJson=`jq --arg i $i --arg slug $templateSlug '{r: .records[$i | tonumber], s: $slug}' dump.json`

	    # Compile template with template json
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

echo "Done."
