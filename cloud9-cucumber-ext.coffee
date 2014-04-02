define (require, exports, module) ->

    ext = require "core/ext"
    ide = require "core/ide"
    commands = require "ext/commands/commands"
    editors = require "ext/editors/editors"
    completer = require 'ext/language/complete'


    module.exports = ext.register "ext/cucumber/cucumber", {
        name     : "Cucumber",
        alone    : true,
        deps     : [],
        type     : ext.GENERAL,
        nodes : [],
        hook : ->
            ide.addEventListener "socketMessage", @onMessage.bind(@)
            commands.addCommand {
                name: "autocomplete",
                bindKey: {mac: "Command-Shift-Space", win: "Ctrl-Shift-Space"},
                hint: "autocomplete current line",
                exec: =>
                    @autocomplete()
            }
        ,

        autocomplete: ->
            line = @getCurrentLine()
            if not line
                return
            type = undefined
            if /(Given|When|Then|And).+/.test line 
                type = 'step'
            else 
                if /@(\w|\W).+/.test line
                    type = 'tag'
                else
                    return
            data = {
                command: 'cucumber-autocomplete',
                line: line,
                type: type
            } 
            ide.send data
        ,

        getCurrentLine: (leftWhitespace) ->
            editor = editors.currentEditor.amlEditor.$editor;
            pos = editor.getCursorPosition();
            line = editor.getSession().getLine(pos.row);
            if not leftWhitespace? or not leftWhitespace 
                line = line.replace(/(^\s+)/,'');
            line
            # cursor = ide.getActivePage()?.$editor?.getSelection()?.getCursor()
            # if not (cursor?.row)?
            #     return off
            # if not ide.getActivePage().$editor.getSelection().doc?.$lines?.length? 
            #     return off
            # if ide.getActivePage().$editor.getSelection().doc.$lines.length > cursor.row
            #     line = ide.getActivePage().$editor.getSelection().doc.$lines[cursor.row]
            #     return line.slice 0, cursor.column + 1
            # else
            #     return off


        onMessage: (e) ->
            message = e.message
            if message.type isnt 'result' or message.subtype isnt 'cucumber-autocomplete'
                return
            if not message.body? 
                return
            line = @getCurrentLine()
            if not line 
                return
            if line.indexOf(message.body.line) is -1
                return
            matches = message.body.matches
            if not matches.length
                return
            results = []
            undigitedLine = line.replace /\b[0-9]{1,}\b/, '$d' #front-trimmed line with $d instead of digits 
            undigitedRealLine = @getCurrentLine(on).replace /\b[0-9]{1,}\b/, '$d' #line with $d instead of digits
            for match in matches
                if match.indexOf undigitedLine isnt -1
                    match = match.substring undigitedLine.length
                    results.push {
                        name: @getCurrentLine(on) + match, 
                        replaceText: @getCurrentLine(on) + match
                        identifierRegex: /./
                    }
            console.log matches
            editor = editors.currentEditor.amlEditor.$editor;
            pos = editor.getCursorPosition();
            completer.showCompletionBox results, line, pos.row, pos.column 
            
            
       
        # enable : function(){
        #     this.nodes.each(function(item){
        #         item.enable();
        #     });
        # },

        # disable : function(){
        #     this.nodes.each(function(item){
        #         item.disable();
        #     });
        # },

        # destroy : function(){
        #     this.nodes.each(function(item){
        #         item.destroy(true, true);
        #     });
        #     this.nodes = [];
        # },

    }



