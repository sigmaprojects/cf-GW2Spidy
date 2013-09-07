/**
********************************************************************************
ColdFusion implemenation of the GW2 Spidy Public API

Author:		Don Quist
Web:		www.sigmaprojects.org
Email:		don@sigmaprojects.org
Github:		https://github.com/sigmaprojects/

GW2 Spidy:
	https://github.com/rubensayshi/gw2spidy/
	https://github.com/rubensayshi/gw2spidy/wiki/API-v0.9

********************************************************************************
*/
component output=false  {

	/**
	* Init
	* @URI The URL Endpoint for the API
	* @Version API Version
	* @Format the default return format for responses (json/xml)
	*/
	public cfGW2SpidyAPI function init(
		URI			= 'http://www.gw2spidy.com/api/',
		Version		= 0.9,
		Format		= 'json'
	) {
		
		variables.APIURL = trim(arguments.URI) & 'v' & arguments.Version & '/' & arguments.Format & '/';
		variables.Version = trim(arguments.Version);
		variables.Format = trim(arguments.Format);
		
	}

	/**
	* Get all Item Types
	* Results are cached server side for up to 24 hours
	* Subtypes start their IDs from 0, for every top level type, following ArenaNet's design ;)
	*/
	public array function getTypes() {
		var response = call(method='types');
		if( structKeyExists(response,'results') ) {
			return response.results;
		} else {
			_throw(Detail='Expected array of Results',extendedInfo=response);
		}
	}

	/**
	* Get all Crafting Disciplines
	* Results are cached server side for up to 24 hours
	*/
	public array function getDisciplines() {
		var response = call(method='disciplines');
		if( structKeyExists(response,'results') ) {
			return response.results;
		} else {
			_throw(Detail='Expected array of Results',extendedInfo=response);
		}
	}
	
	/**
	* Get all Rarities
	* Results are cached server side for up to 24 hours
	*/
	public array function getRarities() {
		var response = call(method='rarities');
		if( structKeyExists(response,'results') ) {
			return response.results;
		} else {
			_throw(Detail='Expected array of Results',extendedInfo=response);
		}
	}

	/**
	* Get all Items
	* Results are cached server side for up to 3 minutes
	* @Type either an ID of a top level type or use *all*
	*/
	public array function getAllItems(
		String		Type		= 'all'
	) {
		var response = call(method='all-items',URIAppend=arguments.Type);
		if( structKeyExists(response,'results') ) {
			return response.results;
		} else {
			_throw(Detail='Expected array of Results',extendedInfo=response);
		}
	}

	/**
	* Get all Items
	* Results are cached server side for up to 3 minutes
	* If you need high frequency of updates, this is what you want to use (and what I want you to use!).
	* @dataId the ID of the item you want to retrieve data for
	*/
	public struct function getItem(
		Required	String		dataId
	) {
		var response = call(method='item',Verb='POST',Args=arguments,URIAppend=arguments.dataID);
		if( IsStruct(response) && StructCount(response) && structKeyExists(response,'result') ) {
			return response.result;
		} else {
			_throw(Detail='Expected struct containing Result',extendedInfo=response);
		}
	}

	/**
	* Get Item Listings
	* Results are cached server side for up to 15 minutes
	* Data is ordered descending by date/time
	* @dataId the ID of the item you want to retrieve listings for
	* @BuyOrSell whether you want the sell or the buy listings, use singular and lowercase: sell or buy
	* @Page page offset
	*/
	public struct function getListings(
		Required	String		dataId,
					String		BuyOrSell,
					Numeric		Page		= 1
	) {
		var response = call(method='listings',Args=arguments,URIAppend=arguments.dataID & '/' & arguments.BuyOrSell & '/' & arguments.Page);
		if( IsStruct(response) && StructCount(response) && structKeyExists(response,'results') ) {
			return response;
		} else {
			_throw(Detail='Expected struct containing at least an Array of Results',extendedInfo=response);
		}
	}

	/**
	* Search Items
	* Results are cached server side for up to 15 minutes
	* I strongly ask and encourage you, please use the getItem API method if at all possible!
	* This API method is really ment for adhoc usage, not for bigger automated usage!
	* @name the name of the item you're looking for
	*/
	public struct function itemSearch(
		Required	String		Name,
					Numeric		Page		= 1
	) {
		var response = call(method='item-search',Args=arguments,URIAppend=URLEncodedFormat(arguments.Name) & '/' & arguments.Page);
		if( IsStruct(response) && StructCount(response) && structKeyExists(response,'results') ) {
			return response;
		} else {
			_throw(Detail='Expected struct containing at least an Array of Results',extendedInfo=response);
		}
	}

	/**
	* Get Recipes
	* Results are cached server side for up to 24 hours
	* @type either an ID of a discipline or use *all*
	* @Page page offset
	*/
	public struct function getRecipes(
					String		type		= 'all',
					Numeric		Page		= 1
	) {
		var response = call(method='recipes',Args=arguments,URIAppend=URLEncodedFormat(arguments.type) & '/' & arguments.Page);
		if( IsStruct(response) && StructCount(response) && structKeyExists(response,'results') ) {
			return response;
		} else {
			_throw(Detail='Expected struct containing at least an Array of Results',extendedInfo=response);
		}
	}

	/**
	* Get Recipe Data
	* Results are cached server side for up to 15 minutes
	* @dataId the ID of the recipe you want to retrieve data for
	*/
	public struct function getRecipe(
		Required	String		dataId
	) {
		var response = call(method='recipe',Args=arguments,URIAppend=arguments.dataId);
		if( IsStruct(response) && StructCount(response) && structKeyExists(response,'result') ) {
			return response.result;
		} else {
			_throw(Detail='Expected struct containing a Result',extendedInfo=response);
		}
	}

	/**
	* Get Current Gem Price
	* Results are cached server side for up to 15 minutes
	* Prices are for 100 gold -> x amount of gems
	* and for 100 gems -> x amount of coin
	*/
	public struct function getGemPrice() {
		var response = call(method='gem-price');
		if( IsStruct(response) && StructCount(response) && structKeyExists(response,'result') ) {
			return response.result;
		} else {
			_throw(Detail='Expected struct containing a Result',extendedInfo=response);
		}
	}



	private struct function call(
		Required	String		Method,
					Struct		Args		= {},
					String		Verb		= 'GET',
					String		URIAppend	= ''
	) {
		var httpService = new http();
		var _Verb = ( arguments.verb eq 'POST' && StructCount(arguments.Args) ? 'POST' : 'GET' );
		var paramType = ( _Verb eq 'GET' ? 'url' : 'formfield' );

		httpService.setURL( variables.APIURL & arguments.Method & (len(trim(arguments.URIAppend)) ? '/' & arguments.URIAppend : '' ) );
		httpService.setMethod( _Verb );

		for(var Key in arguments.Args) {
			if( structKeyExists(arguments.Args,Key) && !IsNull(arguments.Args[Key]) ) {
				httpService.addParam(type=paramType,name=Key,value=arguments.Args[Key]);
			} 
		}

		var result = httpService.send().getPrefix();

		if( result.statuscode contains '200' && structKeyExists(result,'filecontent') && isJSON(result.filecontent) ) {
			
			return deserializeJSON( result.filecontent );
			
		} else {
			_throw(Detail='Unexpected Response from API',extendedInfo=result.filecontent);
		}
	}


	private void function _throw(
		String		Message			= 'Unexpected Response',
		String		Type			= 'Application',
		String		Detail			= '',
		Any			extendedInfo	= ''
	) {
		throw(
			message			= arguments.Message,
			type			= arguments.Message,
			detail			= arguments.Detail,
			extendedInfo	= ( IsSimpleValue(arguments.ExtendedInfo) ? arguments.extendedInfo : serializeJson(arguments.extendedInfo) )
		);
	}


}