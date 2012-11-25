(function ($) {
    'use strict';
    var pluginName = 'exampleRunner',
        defaults = {
            propertyName: "value"
        };

    function Plugin(element, options) {
        this.element = element;
        this.options = $.extend({}, defaults, options);
        var currentPluggin = this;

        this.runExample = function () {
	  var payload_signature = $(element).data('sig');
          var script_payload = $(element).find('code').text();
	  var script_package = {
	    signature: payload_signature,
	    script_payload: script_payload
	  };

	  $.ajax({
	    url: 'http://git-hook-responder.herokuapp.com/deferred_code',
	    data: script_package,
	    type: 'GET',
	    crossDomain: true,
	    dataType: 'jsonp',
	    success: function(data) {
	      console.log('received future result: ' + data);
	      // if(data.match(/invalid signed code/)) {
	      // 	$(element).append('<div class="results-container"><div>results:</div><pre class="run-results"></pre></div>');
	      // 	$('.run-results').html(data);
	      // } else {
	      // 	var result_future_data = $.parseJSON(data);
	      // 	if(result_future_data['results_location']) {
	      // 	  var results_location = result_future_data['results_location']
	      // 	  currentPluggin.getFutureResult(results_location);
	      // 	}
	      // }
	    },
	    error: function() { alert('Failed!'); }
	  });

        };

      this.getFutureResult = function(results_location) {
	$.getJSON('http://git-hook-responder.herokuapp.com'+results_location, function(data) {
	  if(data['not_complete']) {
            console.log('data not ready trying again');
            setTimeout('currentPluggin.getFutureResult(results_location);', 3000);
	  } else {
	    if(data && data['results']) {
	      $(element).append('<div class="results-container"><div>results:</div><pre class="run-results"></pre></div>');
              $('.run-results').html(data['results']);
	    }
	  }
	});
      };

        this.addRunButton = function () {
          $(element).append('<input type="submit" class="run-button" name="runner" value="run"></input>');
	  $('.run-button').click(function() {
	    currentPluggin.runExample();
	    return false;
	  });
	};

        this.init();
        return this;
    }

    Plugin.prototype.init = function () {
      this.addRunButton();
    };

    $.fn[pluginName] = function (options) {
        return this.each(function () {
            if (!$.data(this, 'plugin_' + pluginName)) {
                $.data(this, 'plugin_' + pluginName, new Plugin(this, options));
            }
        });
    };

}(jQuery));

$('.ruby-runner').exampleRunner({});