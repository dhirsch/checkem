
class Parameter
    constructor: (str) ->
        x = str.split("=")
        @name = x[0]
        @val = if x.length >  1 then x[1] else ""
        console.log("Created parameter #{@name}=#{@val}")

class URL
    constructor: (@urlstring) -> 
        @warnings = []
        @errors = []
        @params = []
        @rawparams = []
        @qs = ""
        @hash = ""
        @destination = ""
        @paramnames = []
        @clicktracker = ""


        # split the url at # 
        hash_split = @urlstring.split('#')
        if hash_split.length > 1
            @hash = hash_split[1]

        # separate out the destination from the query string
        query_split = hash_split[0].split('?')
        @destination = query_split[0]
        switch query_split.length
            when 1
                @warnings.push("No parameters found")
            when 2
                @qs = query_split[1]
            when 3
                if useDCClickTracker()
                    @clicktracker = query_split[0]
                    @destination = query_split[1]
                    @qs = query_split[2]
                else   
                    @errors.push("Multiple question marks (?) found") 
            else
                @errors.push("Multiple question marks (?) found")

        # is there is a query string, process it now
        if @qs.length > 0
            
            # split it into an array of Parameters
            @rawparams = (new Parameter(x) for x in @qs.split("&"))
            for p in @rawparams
                console.log("Processing #{p.name}, #{p.val}")
                if @params[p.name]? then @warnings.push("The parameter #{p.name} was used multiple times")
                @params[p.name] = p.val

        # a little error checking for spaces
        if _.contains(@destination, ' ') then @errors.push('Space found in destination')
        if _.contains(@hash, ' ') then @errors.push('Space found in hash')

        for name, value of @params
            if _.contains(name, ' ') then @errors.push("Space found in the name of parameter '#{name}'")
            if _.contains(value, ' ') then @errors.push("Space found in the value '#{value}' of parameter '#{name}'")


### 
on page callbacks
###
$ ->
    $('#url-input-form').submit (event) ->
        event.preventDefault()
        url_string_list = $.trim($('#urls').val()).split("\n")
        emptyOutput()

        urls = (new URL(u) for u in url_string_list)

        names = []
        params = []
        destinations = []
        clicktrackers = []
        error_count = 0
        warning_count = 0

        for url in urls
            error_count += url.errors.length
            warning_count += url.warnings.length

            # add the destination to the list of unique destnations
            if url.destination not in destinations then destinations.push(url.destination)

            if useDCClickTracker() and url.clicktracker.length > 0 then clicktrackers.push(url.clicktracker)

            # iterate over the parameters, adding them to the name list if unique
            for name, value of url.params
                if name not in names then names.push(name)

                # params[name] should be an array of values, so if it does not exist,create the array first
                if not params[name]? then params[name] = []
                params[name].push(value)

        # now the list of parameters is complete, so we can add the header to the table
        table = $('#url-parts')
        tpl = '{{#names}}<th>{{.}}</th>{{/names}}'
        rendered = if useDCClickTracker() then "<th>Click Tracker</th>" else ""
        rendered += Mustache.render(tpl, { names : names })
        table.append("<thead><th>Destination</th>#{rendered}</thead>")


        # need to do the entire loop again because the first run creates the list of parameters
        # and only now can we add them in the same order for each line
        for url in urls

            # add a row to the url-parts table
            tpl = """
            <td>{{destination}}
                <div class="warnings"><ul>{{#warnings}}<li>{{.}}</li>{{/warnings}}</ul></div>
                <div class="errors"><ul>{{#errors}}<li>{{.}}</li>{{/errors}}</ul></div>
            </td>
            """
            content = Mustache.render(tpl, {destination : url.destination, warnings: url.warnings, errors: url.errors })
            if useDCClickTracker() 
                content += "<td>#{url.clicktracker}</td>"
            for name in names
                v = url.params[name] or ""
                content += "<td>#{v}</td>"

            row = $('<tr></tr>').html(content)
            $('#url-parts').append(row)

        # finally, add the unique values
        tpl = """
        <div class="col-md-3" id="">
            <h4>{{name}}</h4>
            <ul>{{#values}}<li>{{.}}</li>{{/values}}
            </ul>
        </div>
        """
        for name, val of params
            rendered = Mustache.render(tpl, {name : name, values : _.uniq(val)})
            $('#value-lists').append(rendered)

        rendered = Mustache.render(tpl, {name : "Click Tracker", values : clicktrackers })
        $('#value-lists').append(rendered)


        if (error_count is 0 and warning_count is 0) 
            msg = "<li>Congratulations - <span class='warnings'>No Warnings</span> or <span class='errors'>Errors</span> in #{urls.length} records!</li>"
        else 
            msg = "<li>There were <span class='errors'>#{error_count} errors</span> and <span class='warnings'>#{warning_count} warnings</span> found in #{urls.length} records.</li>"
        $('#errors').append(msg)    


        $('#output').show(1000) 


    $('#url-input-cancel').click (event) ->
        event.preventDefault()
        $('#output').hide(1000)
        emptyOutput()
        $('#urls').val("")



emptyOutput = () -> 
    $('#errors').empty()
    $('#url-parts').empty()
    $('#value-lists').empty()

useDCClickTracker = () -> 
    $('#dblclick-tracker').prop('checked')

useGAParams = () ->
    $('#ga-params').prop("checked")


url1 = "http://www.vizio.com/audio-overview/?utm_campaign=vizio-soundbar&utm_medium=paid social&utm_source=fbx&utm_content=us-bt-al-v1-ba-s154x154&ci_linkid=vizio-soundbar_paid social_fbx_us-bt-al-v1-ba-s154x154"
u1 = new URL(url1)


