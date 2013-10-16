(function($) {

//throttle stolen from bootstrap typeahead. 
  // https://github.com/twitter/typeahead.js/blob/master/src/utils.js#L115
  function throttle(func, wait) {
    var context, args, timeout, result, previous, later;

    previous = 0;
    later = function() {
      previous = new Date();
      timeout = null;
      result = func.apply(context, args);
    };

    return function() {
      var now = new Date(),
          remaining = wait - (now - previous);

      context = this;
      args = arguments;

      if (remaining <= 0) {
        clearTimeout(timeout);
        timeout = null;
        previous = now;
        result = func.apply(context, args);
      }

      else if (!timeout) {
        timeout = setTimeout(later, remaining);
      }

      return result;
    };
  };

  function debounce(func, wait, immediate) {
    var timeout, result;

    return function() {
      var context = this, args = arguments, later, callNow;

      later = function() {
        timeout = null;
        if (!immediate) { result = func.apply(context, args); }
      };

      callNow = immediate && !timeout;

      clearTimeout(timeout);
      timeout = setTimeout(later, wait);

      if (callNow) { result = func.apply(context, args); }

      return result;
    };
  }

  var last_fetched = null;
  var update = function() {
    console.log("updating made it through debounce")

    var form     = $(this).closest("form");
    var uri      = form.attr("action");
    var q        = form.serialize();

    if (q !== last_fetched) {
          console.log("fetching for " + q)
      last_fetched = q;       
      $.ajax({
        url:      uri,
        data:     q,
        dataType: "html",
        success: function(data) {
          console.log("results in")
          var replace_content_selector = "*[data-instant-search=content]"


          // pull out just the div we want, using code copied from
          // jquery "load" function feature
          var extracted_data = $("<div>").append( $.parseHTML( data ) ).find( replace_content_selector );

          form.closest(".facet_extended_list").find(replace_content_selector).replaceWith(extracted_data);   
        }
      });
    }
      
    
  };


  var last_value = null;
  // Add behavior to the text field, register on document
  // with delegation, so we get forms added to the page
  // with ajax. 
  // keydown will have some false positives like pressing
  // the shift key by itself, sorry -- we make sure to throttle,
  // and we're good. 
  // click catches html5 search input reset too. sigh. 
  $(document).on("keyup click", "form.facet_browse_search input[type=search]", function() {
    // since we're watching keydown, we get false positives sometimes,
    // on shift key and such. so use a variable to make sure content has
    // really changed, or our throttling will end up executing no-op
    // searches and postponing real searches. 
    new_value = $(this).val();
    if (last_value === null)
      last_value = new_value;

    if (new_value !== last_value) {
      last_value = new_value;
      debounce(update, 300).apply(this);
    }
  });





})(jQuery);