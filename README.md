# BlacklightFacetBrowse

I wrote this for my needs; it may not meet yours; please
feel free to fork if you like. 

## Sorry, Blacklight 3.5

At my place of work, we arecurrently on Blacklight 3.5.0, and I needed
to write something that would work for us. 

There are some significant changes in more recent BL's, especially with
CSS (Bootstrap) and JS. I did not have time/energy to make something that
would work out of the box on everything from BL 3.5 to present. 

It will probably need some adjustments for modern BL's. I did my
best to write code that wouldn't be too hard to adjust for modern
BL's, and had the write hook points and such.  If someone wants
to help make this safe for BL recent, pull requests welcome -- 
so long as they don't break for BL 3.5.0, sorry!

## Tests

It overwhelmed me to try and do true integration testing with
BL and Rails -- especially multiple versions of BL and Rails, in
combination! -- and especially trying to implement the testing
it in a _maintainable_ and _comprehensible_ way. 

I did the best I could for _unit test_ coverage of this gem,
but it's got virtually no _integration_ test coverage -- it
doesn't test in the context of a real Blacklight app or even
mostly a real Rails app, it just mocks up harnesses to test
individual components with assumed environments. 

Yeah, this is fragile -- and means some things aren't
really barely tested at all (views, not so much).

But it was really overwhelming and was taking me many
multiples of the time it took to write the functionality
to try and set up testing. Sorry! I did what I could. 
Pull requests welcome, if true integration testing
can be done in a non-horrible-to-maintain way. 