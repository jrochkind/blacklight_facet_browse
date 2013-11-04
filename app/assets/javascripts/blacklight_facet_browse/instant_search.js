(function($) {


  var browse_data = function(element) {
    var data = $(element).data("facet_browse");

    if (data === undefined) {
      data = $(element).data("facet_browse", {})
    }

    return data;
  }


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
  
  var update = function(text_field) {
    var dom_data = browse_data(text_field);
    if (dom_data.updates_in_progress === undefined)
      dom_data.updates_in_progress = 0;


    var form     = $(text_field).closest("form");
    var uri      = form.attr("action");
    var q        = form.serialize();

    var ajax_uri = form.data("ajax-url");
    if (ajax_uri === "disabled") {
      // requested to do nothing please. 
      return;
    } else if (ajax_uri === undefined) {
      ajax_uri = uri;
    }

    $(this).closest("form").find(".facet-browse-loading").addClass("active")          

    console.log("fetching for " + q)

    dom_data.updates_in_progress++;

    $.ajax({
      url:      ajax_uri,
      data:     q,
      dataType: "html",
      success: function(response) {
        console.log("results in")

        var replace_content_selector = "*[data-instant-search=content]"

        // pull out just the div we want, using code copied from
        // jquery "load" function feature
        var partial_html = $("<div>").append( $.parseHTML( response ) ).find( replace_content_selector );


        // We need to attach our AJAX popup window behavior
        // the the 'more' link, if any. This is doing it for BL 3.5, sorry
        // will need something else in more recent Blacklight (or a patch to 
        // more recent BL to use jquery 'on')
        if (Blacklight !== undefined && 
            Blacklight.do_more_facets_behavior !== undefined &&
            Blacklight.do_more_facets_behavior.selector !== undefined &&
            $.uiExt !== undefined &&
            $.uiExt.ajaxyDialog !== undefined) {

            partial_html.find( Blacklight.do_more_facets_behavior.selector ).ajaxyDialog({
              width: $(window).width() / 2,  
              chainAjaxySelector: "a.next_page, a.prev_page, a.sort_change"
            });
        }

        form.closest(".facet_list").find(replace_content_selector).replaceWith(partial_html); 

        dom_data.updates_in_progress--;

        if (dom_data.updates_in_progress === 0)
          $(form).find(".facet-browse-loading").removeClass("active");
      }
    });
  };


  // Add behavior to the text field, register on document
  // with delegation, so we get forms added to the page
  // with ajax. 
  // keydown will have some false positives like pressing
  // the shift key by itself, sorry -- we make sure to throttle,
  // and we're good. 
  // click catches html5 search input reset too. sigh. 
  $(document).on("keyup click", "form.facet_browse_search input[type=search]", function() {
    var data = browse_data(this);
    
    // Have to create the debounced one inside the function
    // and attached to the specific input, 
    // so it's debounced per input field. 
    if (data.update === undefined)
      data.update = debounce(update, 400);



    // since we're watching keydown, we get false positives sometimes,
    // on shift key and such. so use a variable to make sure content has
    // really changed, or our throttling will end up executing no-op
    // searches and postponing real searches. 
    var new_value = $(this).val();
    if (data.last_value === undefined) {
      //intentionally use DOM getAttribute to get _original_ html
      // source 'value', not current value, which may have already
      // changed as result of a click on 'reset' icon sometimes. 
      data.last_value = this.getAttribute('value') || "";
    }

    if (new_value !== data.last_value) {
      console.log("actual change: " + new_value)
      data.last_value = new_value;

      $(this).closest("form").find(".facet-browse-loading").addClass("active")

      data.update(this);
    }
  });





})(jQuery);