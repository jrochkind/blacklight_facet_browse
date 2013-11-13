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

    console.log(logTime() + "fetching for " + q)

    dom_data.updates_in_progress++;

    $.ajax({
      url:      ajax_uri,
      data:     q,
      dataType: "html",
      success: function(response) {
        console.log(logTime() + "results in")

        var replace_content_selector = "*[data-instant-search=content]"

        // pull out just the div we want, using code copied from
        // jquery "load" function feature
        var partial_html = $("<div>").append( $.parseHTML( response ) ).find( replace_content_selector );

        // the element that's gonna get replaced with our new stuff
        var target_element = form.closest(".facet_list").find(replace_content_selector);

        window.Blacklight.facetBrowse.addHandlersToContent(partial_html, target_element);
        
        target_element.replaceWith(partial_html); 

        dom_data.updates_in_progress--;

        if (dom_data.updates_in_progress === 0)
          $(form).find(".facet-browse-loading").removeClass("active");
      },
      error: function(jqXHR, textStatus, errorThrown) {
        dom_data.updates_in_progress--;        
        if (dom_data.updates_in_progress === 0)
          $(form).find(".facet-browse-loading").removeClass("active");

        var replace_content_selector = "*[data-instant-search=content]"

        form.closest(".facet_list").find(replace_content_selector).html("Sorry, an error occured: " + textStatus + ' ' + errorThrown );
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

  // When we execute an 'instant search', putting search results
  // on the screen with AJAX -- we need to make sure links within
  // those ajax-loaded search results are themselves properly enhanced
  // for ajax actions:
  //
  // 1. 'more' links in sidebar content need to be enhanced to load
  //     in js modal, not via browser nav. 
  // 2. When already in a modal dialog, and loading content from prefix
  //    search, next/prev/sort navigational links in loaded content
  //    need to be enhanced to stay within modal. 
  //
  // This code is for Blacklight 3.5 and won't work with future bootstrapped
  // BL. Future BL _may_ not need any code like this at all, if it properly 
  // implements ajaxy behavior with JQuery 'on' on a body element. Alternately,
  // if future BL still needs logic, it will need to be _different_ than
  // this BL 3.5 compatible logic. 
  // 
  // So we provide the logic in an attribute of the Blacklight object,
  // so local apps can over-ride it with a no-op function or other
  // logic. 
  if (window.Blacklight === undefined) {
    window.Blacklight = {};
  }
  if (window.Blacklight.facet_browse === undefined) {
    window.Blacklight.facetBrowse = {};
  }
  // only define if not already defined, define your own logic
  // first if you want. 
  if (window.Blacklight.facetBrowse.addHandlersToContent === undefined) {
    window.Blacklight.facetBrowse.addHandlersToContent = function(partial_html, target_element) {
        // Can only do anything if ajaxyDialog jquery plugin is loaded (BL 3.5)
        if (Blacklight !== undefined && 
            $.uiExt !== undefined &&
            $.uiExt.ajaxyDialog !== undefined) {

            // For ajax loads in the sidebar, find any 'more' links
            // and make sure they will trigger load in modal. 
            partial_html.find("a.more_facets_link").ajaxyDialog({
              width: $(window).width() / 2,  
              chainAjaxySelector: "a.next_page, a.prev_page, a.sort_change"        
            });
            
            // For already being inside the modal, find next/previous/sort 
            // buttons and make sure they will trigger
            // load inside the modal -- if it's already in a jquery-ui dialog!
            if (target_element.closest(".ui-dialog").size() > 0) {
              partial_html.find("a.next_page, a.prev_page, a.sort_change").ajaxyDialog({
                width: $(window).width() / 2,  
                chainAjaxySelector: "a.next_page, a.prev_page, a.sort_change" 
              });
            }
        }
    };    
  }

  function logTime() {
    d = new Date();
    return d.toLocaleTimeString() + " " + d.getMilliseconds();
  }



})(jQuery);
