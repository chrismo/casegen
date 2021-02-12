# CaseGen

CaseGen is a small Ruby external DSL for generating combinations of variables,
optionally restricted by a set of rules.

## Usage

This input file:

		sets
		------------
		payment: Credit, Check, Online Bank
		amount: 100, 1,000, 10,000
		shipping: Ground, Air
		ship to country: US, Outside US
		bill to country: US, Outside US
		
		
		rules(sets)
		---------------------------
		exclude shipping = Ground AND ship to country = Outside US
		  Our ground shipper will only ship things within the US.
		
		exclude payment = Check AND bill to country == Outside US
		  Our bank will not accept checks written from banks outside the US.
		
		exclude payment = Online Bank AND amount == 1,000
		exclude payment = Online Bank AND amount == 10,000
		  While the online bank will process amounts > $1,000, we've experienced
		  occasional problems with their services and have had to write off some
		  transactions, so we no longer allow this payment option for amounts greater
		  than $1,000
		
		exclude ship to country = US AND bill to country = Outside US
		  If we're shipping to the US, billing party cannot be outside US
		
		
		console(rules)
		----------


produces this output:
        
        +-------------+--------+----------+-----------------+-----------------+
        |   payment   | amount | shipping | ship to country | bill to country |
        +-------------+--------+----------+-----------------+-----------------+
        | Credit      | 100    | Ground   | US              | US              |
        | Credit      | 100    | Air      | US              | US              |
        | Credit      | 100    | Air      | Outside US      | US              |
        | Credit      | 100    | Air      | Outside US      | Outside US      |
        | Credit      | 1,000  | Ground   | US              | US              |
        | Credit      | 1,000  | Air      | US              | US              |
        | Credit      | 1,000  | Air      | Outside US      | US              |
        | Credit      | 1,000  | Air      | Outside US      | Outside US      |
        | Credit      | 10,000 | Ground   | US              | US              |
        | Credit      | 10,000 | Air      | US              | US              |
        | Credit      | 10,000 | Air      | Outside US      | US              |
        | Credit      | 10,000 | Air      | Outside US      | Outside US      |
        | Check       | 100    | Ground   | US              | US              |
        | Check       | 100    | Air      | US              | US              |
        | Check       | 100    | Air      | Outside US      | US              |
        | Check       | 1,000  | Ground   | US              | US              |
        | Check       | 1,000  | Air      | US              | US              |
        | Check       | 1,000  | Air      | Outside US      | US              |
        | Check       | 10,000 | Ground   | US              | US              |
        | Check       | 10,000 | Air      | US              | US              |
        | Check       | 10,000 | Air      | Outside US      | US              |
        | Online Bank | 100    | Ground   | US              | US              |
        | Online Bank | 100    | Air      | US              | US              |
        | Online Bank | 100    | Air      | Outside US      | US              |
        | Online Bank | 100    | Air      | Outside US      | Outside US      |
        +-------------+--------+----------+-----------------+-----------------+
        
        exclude shipping = Ground AND ship to country = Outside US
          Our ground shipper will only ship things within the US.
        
        exclude payment = Check AND bill to country == Outside US
          Our bank will not accept checks written from banks outside the US.
        
        exclude payment = Online Bank AND amount == 1,000
        
        exclude payment = Online Bank AND amount == 10,000
          While the online bank will process amounts > $1,000, we've experienced
          occasional problems with their services and have had to write off some
          transactions, so we no longer allow this payment option for amounts greater
          than $1,000
        
        exclude ship to country = US AND bill to country = Outside US
          If we're shipping to the US, billing party cannot be outside US
     
If you pull the source locally, you can execute this:

   casegen doc/cart.sample.txt     
        
## FAQ

How can I use this lib inside another Ruby file, instead of having a separate
input file?

sample.rb:

	require "bundler/inline"
        
        gemfile do
          source "https://rubygems.org"
          gem "casegen", "~> 2.0"
        end
        
	require 'casegen'
		
	CLabs::CaseGen::CaseGen.new(DATA.read)
		
	__END__
		
	sets
	----
	a: 1, 2
	b: 3, 4
		
	rules(sets)
	-----------
	exclude a = 1
		
	console(rules)
	--------------
		

### Are there other tools similar to CaseGen?

<a href="http://code.google.com/p/tcases/">tcases</a> is one to check out.
Another is <a href="http://www.satisfice.com/tools.shtml">AllPairs</a> by James
Bach.
          
### Hat Tip

To @JoelVanderWerf (https://github.com/vjoel) for his almost long lost enum
library. See http://redshift.sourceforge.net/enum/.
