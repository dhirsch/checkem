/* 
*/

/** 
* Parameter object - a simple keyword/val pair
*
* val is optional 
*/
function Parameter(keyword, val) {
	this.keyword = keyword;
	this.val = val || "";
}

/**
* URL object - parses a full url into their parts and utm tracking parameters
* 
*/
function URL(urlstring) {
	this.warnings = []
	this.errors = [];
	this.destination = "";
	this.path = "";
	this.hash = "";
	this.params = [];
	this.qs = "";
	this.campaign = "";
	this.medium = "";
	this.source = "";
	this.content = "";

	// split into destination and query/hash
	s = urlstring.split("?")
	
	// no query string
	if(s.length == 1) {  
		this.warnings.push("No URL parameters found");
		// since there is no query string, make sure to split on the hash 
		h = s[0].split("#");
		if(h.length == 1) {
			// no hash either
			this.destination = s[0];
			this.hash = "";
		}
		else if(h.length == 2) {
			this.destination = h[0];
			this.hash = h[1];
		}
		else {
			this.errors.push("Multiple #hashes detected")
			this.destination = h[0];
		}
	}
	
	// proper query string
	else if(s.length == 2) { 
		this.destination = s[0];
		
		h = s[1].split("#");
		if(h.length == 1) { // no hash
			this.qs = s[1];
		}
		else if(h.length == 2) { // one hash
			this.qs = h[0];
			this.hash = h[1];
		}
		else {
			this.errors.push("Multiple #hashes detected");
			this.qs = h[0];
		}
	}
	
	// multiple ?s 
	else{ 
		this.errors.push("Multiple (?) question marks detected");
		this.destination = s[0];
	}

	if(_.contains(this.destination," ")) this.errors.push("Space detected in destination");


	// process the query string if its available
	if(this.qs != "") {
		pairs = this.qs.split("&");
		for(var n = 0; n < pairs.length; n++) {
			value = pairs[n];
			param = value.split("=");
			kw = param[0];
			val = param[1] || "";
			if(kw == "utm_campaign") this.campaign = val;
			else if(kw == "utm_medium") this.medium = val;
			else if(kw == "utm_source") this.source = val;
			else if(kw == "utm_content") this.content = val;
			else {
				this.params.push(new Parameter(kw, val));
			}

			if(_.contains(kw, ' ')) this.errors.push("Space detected in keyword '" + kw + "'");
			if(_.contains(val, ' ')) this.errors.push("Space detected in value '" + val + "'");
		}

		if(this.campaign == '') this.warnings.push("Capaign is empty");
		if(this.medium == '') this.warnings.push("Medium is empty");
		if(this.source == '') this.warnings.push("Source is empty");
		if(this.content == '') this.warnings.push('Content is empty');

	}

	if(_.contains(this.destination, ' ')) this.errors.push("Space detected in destination");
	if(_.contains(this.path, ' ')) this.errors.push("Space detected in path");

	console.log("Destination: " + this.destination);
	console.log("Query Srting: " + this.qs);
	console.log("Hash: " + this.hash);
	console.log("Campaign: " + this.campaign);
	console.log("Medium: " + this.medium);
	console.log("Source :" + this.source);
	console.log("Content :" + this.content);
	console.log("Extra parameters: " + this.params);
	console.log("Warnings: " + this.warnings);
	console.log("Errors: " + this.errors);
}

$(function() {
	$('#url-input-cancel').click(function(event) {
		event.preventDefault();
		$('#output').hide(1000);
		emptyOutput();		
		$('#urls').val("");
	})
	$('#url-input-form').submit(function(event) {
		event.preventDefault();
		var url_string_list = $('#urls').val().split("\n");
		emptyOutput();
		$('#output').show(1000);

		var urls = [];
		var campaigns = [];
		var mediums = [];
		var sources = [];
		var contents = [];
		var destinations = [];
		var warning_count = 0;
		var error_count = 0;

		$.each(url_string_list, function(index, value) {
			if($.trim(value).length > 0) {
				var url = new URL(value);

				campaigns.push(url.campaign);
				mediums.push(url.medium);
				sources.push(url.source);
				contents.push(url.content);
				destinations.push(url.destination); 

				warning_count += url.warnings.length;
				error_count += url.errors.length;
				urls.push(url);
			}
		});

		$.get('urlparts.mst', function(template) {
			var rendered = Mustache.render(template, {urls : urls});
			$('#url-parts').html(rendered);
		}, 'html');


		$('#errors').append("<p>Processed " + urls.length + " records. There were <span class='warnings'>" + warning_count + " warnings </span> and <span class='errors'>" + error_count + " errors</span></p>");
		
		tpl = "{{#list}}<li>{{.}}</li>{{/list}}";
		$('#campaigns-list ul').html(Mustache.render(tpl, {list : _.uniq(campaigns)}));
		$('#mediums-list ul').html(Mustache.render(tpl, {list : _.uniq(mediums)}));
		$('#sources-list ul').html(Mustache.render(tpl, {list : _.uniq(sources)}));
		$('#contents-list ul').html(Mustache.render(tpl, {list : _.uniq(contents)}));
		
	});
});


/**
* Clears the output elements (but does not hide them)
*
*/
function emptyOutput() {
	$('#url-parts').empty();
	$('#errors').empty();
	$('#campaigns-list ul').empty();
	$('#mediums-list ul').empty();
	$('#sources-list ul').empty();
	$('#contents-list ul').empty();
}



