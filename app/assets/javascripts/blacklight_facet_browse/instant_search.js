(function($) {


  //debounce taken from underscore library. 
  var debounce = function(func, wait, immediate) {
    var timeout, args, context, timestamp, result;
    return function() {
      context = this;
      args = arguments;
      timestamp = new Date();
      var later = function() {
        var last = (new Date()) - timestamp;
        if (last < wait) {
          timeout = setTimeout(later, wait - last);
        } else {
          timeout = null;
          if (!immediate) result = func.apply(context, args);
        }
      };
      var callNow = immediate && !timeout;
      if (!timeout) {
        timeout = setTimeout(later, wait);
      }
      if (callNow) result = func.apply(context, args);
      return result;
    };
  };

  var updates_in_progress = 0;
  var update = function(text_field) {

    var form     = $(text_field).closest("form");
    var uri      = form.attr("action");
    var q        = form.serialize();

    $(this).closest("form").find(".facet-browse-loading").addClass("active")          

    console.log("fetching for " + q)

    updates_in_progress++;

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

        updates_in_progress--;

        if (updates_in_progress === 0)
          $(form).find(".facet-browse-loading").removeClass("active");
      }
    });
  };
  update = debounce(update, 400);


  var last_value = null;
  // Add behavior to the text field, register on document
  // with delegation, so we get forms added to the page
  // with ajax. 
  // keydown will have some false positives like pressing
  // the shift key by itself, sorry -- we make sure to throttle,
  // and we're good. 
  // click catches html5 search input reset too. sigh. 
  $(document).on("keyup click", ".facet_extended_list form.facet_browse_search input[type=search]", function() {
    // since we're watching keydown, we get false positives sometimes,
    // on shift key and such. so use a variable to make sure content has
    // really changed, or our throttling will end up executing no-op
    // searches and postponing real searches. 
    new_value = $(this).val();
    if (last_value === null)
      last_value = new_value;

    if (new_value !== last_value) {
      console.log("actual change: " + new_value)
      last_value = new_value;

      $(this).closest("form").find(".facet-browse-loading").addClass("active")

      update(this);
    }
  });





})(jQuery);