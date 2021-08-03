component extends="coldbox.system.testing.BaseTestCase" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
		super.afterAll();
	}

	/*********************************** BDD SUITES ***********************************/

	function run( testResults, testBox ){
		describe( "Component.cfc", function(){
			beforeEach( function( currentSpec ){
				setup();
				wireRequest  = prepareMock( getInstance( "cbwire.models.WireRequest" ) );
				componentObj = prepareMock(
					getInstance(
						name          = "cbwire.models.Component",
						initArguments = { "wireRequest" : wireRequest }
					)
				);
			} );

			it( "can instantiate a component", function(){
				expect( isObject( componentObj ) ).toBeTrue();
			} );

			describe( "getId()", function(){
				it( "returns 21 character guid", function(){
					var id = componentObj.getID();
					expect( len( id ) ).toBe( 21 );
					expect( reFindNoCase( "^[A-Za-z0-9-]+$", id ) ).toBeTrue();
				} );
			} );

			describe( "getPath", function(){
				it( "returns empty string by default", function(){
					expect( componentObj.getPath() ).toBe( "" );
				} );

				it( "includes properties we've defined in our component as variables.queryString", function(){
					componentObj.$property(
						propertyName  = "queryString",
						propertyScope = "variables",
						mock          = [ "count" ]
					);

					componentObj.$property(
						propertyName  = "data",
						propertyScope = "variables",
						mock          = { "count" : 2 }
					);

					expect( componentObj.getPath() ).toInclude( "?count=2" );
				} );

				it( "it doesn't duplicate query string params if they are present in cgi.HTTP_REFERER", function(){
					componentObj.$(
						"getHTTPReferer",
						"http://localhost?count=1"
					);
					componentObj.$property(
						propertyName  = "queryString",
						propertyScope = "variables",
						mock          = [ "count" ]
					);

					componentObj.$property(
						propertyName  = "data",
						propertyScope = "variables",
						mock          = { "count" : 2 }
					);

					expect( componentObj.getPath() ).toBe( "http://localhost?count=2" );
				} );
			} );

			describe( "getListeners", function(){
				it( "should return empty struct by default", function(){
					expect( componentObj.getListeners() ).toBe( {} );
				} );

				it( "should return listeners defined on the component", function(){
					componentObj.$property(
						propertyName  = "listeners",
						propertyScope = "variables",
						mock          = { "someEvent" : "someMethod" }
					);
					expect( componentObj.getListeners() ).toBe( { "someEvent" : "someMethod" } );
				} );
			} );

			describe( "getMeta", function(){
				it( "should return the meta", function(){
					expect( componentObj.getMeta().name ).toBe( "cbwire.models.Component" );
				} );

				it( "should cache the results", function(){
					componentObj.$property(
						propertyName  = "meta",
						propertyScope = "variables",
						mock          = "some meta"
					);

					expect( componentObj.getMeta() ).toBe( "some meta" );
					expect( componentObj.getMeta() ).toBe( "some meta" );
				} );

				it( "should return cached results if they exists", function(){
					componentObj.$property(
						propertyName  = "meta",
						propertyScope = "variables",
						mock          = "some meta"
					);
					expect( componentObj.getMeta() ).toBe( "some meta" );
				} );
			} );


			describe( "getInitialData", function(){
				it( "returns a struct", function(){
					expect( componentObj.getInitialData() ).toBeStruct();
				} );

				it( "should include listeners defined on our component", function(){
					componentObj.$property(
						propertyName  = "listeners",
						propertyScope = "variables",
						mock          = { "postAdded" : "doSomething" }
					);
					expect( componentObj.getInitialData().effects.listeners ).toBeArray();
					expect( componentObj.getInitialData().effects.listeners[ 1 ] ).toBe( "postAdded" );
				} );

				it( "returns the component checksum in the serverMemo", function(){
					componentObj.$( "getChecksum", "test" );
					expect( componentObj.getInitialData().serverMemo.checksum ).toBe( "test" );
				} );
			} );

			describe( "getChecksum", function(){
				it( "returns the expected checksum", function(){
					componentObj.$( "getState", { "test" : "checksum" } );
					expect( componentObj.getChecksum() ).toBe( "8D19A0A0D180FFCD52B7DC0B572DC8D3" );
				} );
			} );

			describe( "renderIt", function(){
				it( "throw an error if it's not been implemented on the child class", function(){
					expect( function(){
						componentObj.renderIt();
					} ).toThrow( type = "RenderMethodNotFound" );
				} );
			} );

			describe( "renderView", function(){
				beforeEach( function(){
					componentObj.$property(
						propertyName  = "$renderer",
						propertyScope = "variables",
						mock          = {
							"renderView" : function(){
								return "<div>test</div>";
							}
						}
					);
				} );

				it( "provides rendering", function(){
					expect( componentObj.renderView( "someView" ) ).toInclude( "<div" );
				} );

				it( "should support various outer element tags", function(){
					var outerElements = [ "div", "span", "section" ];

					outerElements.each( function( element ){
						componentObj.$property(
							propertyName  = "$renderer",
							propertyScope = "variables",
							mock          = {
								"renderView" : function(){
									return "<#element#>test</#element#>";
								}
							}
						);
						expect( componentObj.renderView( "someView" ) ).toInclude( "<#arguments.element# wire:id=" );
					} );
				} );

				it( "throws error if there's no outer element to bind to", function(){
					componentObj.$property(
						propertyName  = "$renderer",
						propertyScope = "variables",
						mock          = {
							"renderView" : function(){
								return "test";
							}
						}
					);
					expect( function(){
						componentObj.renderView( "someView" )
					} ).toThrow( type = "OuterElementNotFound" );
				} );
			} );

			describe( "getEmits", function(){
				it( "returns an empty array by default", function(){
					expect( componentObj.getEmits() ).toBeArray();
					expect( arrayLen( componentObj.getEmits() ) ).toBe( 0 );
				} );

				it( "tracks emits", function(){
					componentObj.emit( "someEvent" );
					componentObj.emitSelf( "someOtherEvent" );
					expect( arrayLen( componentObj.getEmits() ) ).toBe( 2 );
				} );
			} );

			describe( "emit", function(){
				it( "invokes a preEmit method on the component if it's defined", function(){
					componentObj.$( "preEmit", true );
					componentObj.emit( "SomeEvent" );
					expect( componentObj.$once( "preEmit" ) ).toBeTrue();
					expect( componentObj.$callLog()[ "preEmit" ][ 1 ].eventName ).toBe( "SomeEvent" );
				} );

				it( "invokes a postEmit method on the component if it's defined", function(){
					componentObj.$( "postEmit", true );
					componentObj.emit( "SomeEvent" );
					expect( componentObj.$once( "postEmit" ) ).toBeTrue();
					expect( componentObj.$callLog()[ "postEmit" ][ 1 ].eventName ).toBe( "SomeEvent" );
				} );

				it( "invokes a preEmit[EventName] method on the component if it's defined", function(){
					componentObj.$( "preEmitBTTF", true );
					componentObj.emit( "BTTF", [ "gigawatt" ] );
					expect( componentObj.$once( "preEmitBTTF" ) ).toBeTrue();
					expect( componentObj.$callLog()[ "preEmitBTTF" ][ 1 ].parameters ).toBe( [ "gigawatt" ] );
				} );

				it( "invokes a postEmit[EventName] method on the component if it's defined", function(){
					componentObj.$( "postEmitBTTF", true );
					componentObj.emit( "BTTF", [ "gigawatt" ] );
					expect( componentObj.$once( "postEmitBTTF" ) ).toBeTrue();
					expect( componentObj.$callLog()[ "postEmitBTTF" ][ 1 ].parameters ).toBe( [ "gigawatt" ] );
				} );
			} );

			describe( "emitSelf", function(){
				it( "tracks the expected values", function(){
					componentObj.emitSelf(
						"test",
						[
							"how",
							"much",
							"wood",
							"could",
							"a",
							"wood",
							"chuck",
							"chuck"
						]
					);
					expect( componentObj.getEmits()[ 1 ] ).toBe( {
						"event"  : "test",
						"params" : [
							"how",
							"much",
							"wood",
							"could",
							"a",
							"wood",
							"chuck",
							"chuck"
						],
						"selfOnly" : true
					} );
				} );
			} );

			describe( "emitUp", function(){
				it( "tracks the expected values", function(){
					componentObj.emitUp( "test", [ "hello", "world" ] );
					expect( componentObj.getEmits()[ 1 ] ).toBe( {
						"event"         : "test",
						"params"        : [ "hello", "world" ],
						"ancestorsOnly" : true
					} );
				} );
			} );

			describe( "emitTo", function(){
				it( "tracks the expected values", function(){
					componentObj.emitTo( "event1", "component1" );
					componentObj.emitTo(
						"event2",
						"component2",
						[ "hello", "world" ]
					);
					expect( componentObj.getEmits()[ 1 ] ).toBe( {
						"event"  : "event1",
						"params" : [],
						"to"     : "component1"
					} );
					expect( componentObj.getEmits()[ 2 ] ).toBe( {
						"event"  : "event2",
						"params" : [ "hello", "world" ],
						"to"     : "component2"
					} );
				} );
			} );

			describe( "refresh", function(){
				it( "fires 'postRefresh' event", function(){
					componentObj.$( "postRefresh", true );
					componentObj.refresh();
					expect( componentObj.$once( "postRefresh" ) ).toBeTrue();
				} );
			} );

			xdescribe( "getMemento", function(){
				it( "returns a struct", function(){
					componentObj.$( "renderIt", "" );
					expect( componentObj.getMemento() ).toBeStruct();
				} );
				it( "returns an empty array of events by default", function(){
					componentObj.$( "renderIt", "" );
					expect( componentObj.getMemento().effects.emits ).toBeArray();
				} );
				it( "returns emitted events", function(){
					componentObj.$( "renderIt", "" );
					componentObj.emit( "event1" );
					componentObj.emitSelf(
						eventName  = "event2",
						parameters = { "hello" : "world" }
					);
					wireRequest.$(
						"getWireComponent",
						componentObj,
						false
					);

					var memento = wireRequest.getMemento();
					expect( memento.effects.emits ).toBeArray();

					expect( arrayLen( memento.effects.emits ) ).toBe( 2 );
					expect( memento.effects.emits[ 1 ] ).toBe( { "event" : "event1", "params" : {} } );
					expect( memento.effects.emits[ 2 ] ).toBe( {
						"event"    : "event2",
						"params"   : { "hello" : "world" },
						"selfOnly" : true
					} );
				} );
			} );

			describe( "getRendering", function(){
				it( "calls the renderIt() method on our component", function(){
					componentObj.$( "renderIt", "got here" );
					expect( componentObj.getRendering() ).toBe( "got here" );
				} );

				it( "returns the cached results in variables.rendering", function(){
					componentObj.$property(
						propertyName  = "rendering",
						propertyScope = "variables",
						mock          = "got here too"
					);
					expect( componentObj.getRendering() ).toBe( "got here too" );
				} );
			} );

			describe( "$relocate", function(){
				it( "passes the relocation to the coldbox render", function(){
					var renderer = getMockBox().createStub();

					renderer.$( "relocate" );
					componentObj.$property(
						propertyName  = "$renderer",
						propertyScope = "variables",
						mock          = renderer
					);

					componentObj.$relocate( uri = "/short-circuit" );

					expect( renderer.$once( "relocate" ) ).toBeTrue();
					expect( renderer.$callLog().relocate[ 1 ].uri ).toBe( "/short-circuit" );
				} );
			} );

			describe( "$set", function(){
				it( "sets data property on our component", function(){
					componentObj.$property(
						propertyName  = "data",
						propertyScope = "this",
						mock          = { "name" : "test" }
					);
					expect( componentObj.data[ "name" ] ).toBe( "test" );
				} );

				it( "fires 'preUpdate[prop] event", function(){
					componentObj.$( "preUpdateName", true );
					componentObj.$set(
						propertyName = "name",
						value        = "test"
					);
					expect( componentObj.$once( "preUpdateName" ) ).toBeTrue();
					expect( componentObj.$callLog()[ "preUpdateName" ][ 1 ][ "propertyName" ] ).toBe( "test" );
				} );

				it( "fires 'postUpdate[prop] event", function(){
					componentObj.$( "postUpdateName", true );
					componentObj.$set(
						propertyName = "name",
						value        = "test"
					);
					expect( componentObj.$once( "postUpdateName" ) ).toBeTrue();
					expect( componentObj.$callLog()[ "postUpdateName" ][ 1 ][ "propertyName" ] ).toBe( "test" );
				} );

				it( "throws an error when 'throwOnMissingSetterMethod' is true", function(){
					componentObj.$property(
						propertyName  = "$settings",
						propertyScope = "variables",
						mock          = { "throwOnMissingSetterMethod" : true }
					);
					expect( function(){
						componentObj.setName( "test" );
					} ).toThrow( type = "WireSetterNotFound" );
				} );

				it( "does not throw an error when 'throwOnMissingSetterMethod' is false", function(){
					componentObj.$property(
						propertyName  = "$settings",
						propertyScope = "variables",
						mock          = { "throwOnMissingSetterMethod" : false }
					);

					expect( function(){
						componentObj.setName( "test" );
					} ).notToThrow( type = "WireSetterNotFound" );
				} );
			} );

			describe( "getState", function(){
				it( "returns empty struct by default", function(){
					expect( componentObj.getState() ).toBe( {} );
				} );

				it( "returns the data property values", function(){
					var state = componentObj.getState();

					componentObj.$property(
						propertyName  = "data",
						propertyScope = "variables",
						mock          = { "count" : 1 }
					);

					expect( componentObj.getState()[ "count" ] ).toBe( 1 );
				} );

				it( "ignores custom functions that are not getters", function(){
					componentObj.$property(
						propertyName = "count",
						mock         = function(){
						}
					);

					var state = componentObj.getState();

					expect( structKeyExists( state, "count" ) ).toBeFalse();
				} );
			} );

			describe( "hydrate()", function(){
				it( "sets properties with values from 'serverMemo' payload", function(){
					var rc = wireRequest.getCollection();

					rc[ "serverMemo" ] = { "data" : { "hello" : "world" } };
					componentObj.$( "setHello", true );
					wireRequest.$(
						"getWireComponent",
						componentObj,
						false
					);
					wireRequest.hydrate();
					expect( componentObj.$once( "setHello" ) ).toBeTrue();
				} );

				it( "fires 'preHydrate' event", function(){
					componentObj.$( "$preHydrate", true );
					wireRequest.$(
						"getWireComponent",
						componentObj,
						false
					);
					wireRequest.hydrate();
					expect( componentObj.$once( "$preHydrate" ) ).toBeTrue();
				} );

				it( "fires 'postHydrate' event", function(){
					componentObj.$( "$postHydrate", true );
					wireRequest.$(
						"getWireComponent",
						componentObj,
						false
					);
					wireRequest.hydrate();
					expect( componentObj.$once( "$postHydrate" ) ).toBeTrue();
				} );

				describe( "syncInput", function(){
					it( "executes a setter method on component object", function(){
						var rc = wireRequest.getCollection();

						rc[ "updates" ] = [
							{
								"type"    : "syncInput",
								"payload" : {
									"name"  : "message",
									"value" : "We have input"
								}
							}
						];

						componentObj.$( "setMessage", true );
						wireRequest.$(
							"getWireComponent",
							componentObj,
							false
						);
						wireRequest.hydrate();
						expect( componentObj.$once( "setMessage" ) ).toBeTrue();
						expect( componentObj.$callLog().setMessage[ 1 ][ 1 ] ).toBe( "We have input" );
					} );
				} );

				describe( "callMethod", function(){
					it( "executes method on component object", function(){
						var rc = wireRequest.getCollection();

						rc[ "updates" ] = [
							{
								"type"    : "callMethod",
								"payload" : { "method" : "whyAmIAwakeAt3am" }
							}
						];

						componentObj.$( "whyAmIAwakeAt3am", true );
						wireRequest.$(
							"getWireComponent",
							componentObj,
							false
						);
						wireRequest.hydrate();
						expect( componentObj.$once( "whyAmIAwakeAt3am" ) ).toBeTrue();
					} );

					it( "throws error if you try to call action on component that doesn't exist", function(){
						var rc = wireRequest.getCollection();

						rc[ "updates" ] = [
							{
								"type"    : "callMethod",
								"payload" : { "method" : "whyAmIAwakeAt3am" }
							}
						];

						expect( function(){
							wireRequest.$(
								"getWireComponent",
								componentObj,
								false
							);
							wireRequest.hydrate();
						} ).toThrow( type = "WireActionNotFound" );
					} );

					it( "passes in params to the method were calling if they are provided", function(){
						var rc = wireRequest.getCollection();

						rc[ "updates" ] = [
							{
								"type"    : "callMethod",
								"payload" : {
									"method" : "resetName",
									"params" : [ "George" ]
								}
							}
						];

						componentObj.$( "resetName" );
						wireRequest.$(
							"getWireComponent",
							componentObj,
							false
						);
						wireRequest.hydrate();

						var callLog = componentObj.$callLog()[ "resetName" ][ 1 ];

						expect( componentObj.$once( "resetName" ) ).toBeTrue();
						expect( callLog[ "1" ] ).toBe( "George" );
					} );

					it( "uses set", function(){
						var rc = wireRequest.getCollection();

						rc[ "updates" ] = [
							{
								"type"    : "callMethod",
								"payload" : {
									"method" : "$set",
									"params" : [ "name", "George" ]
								}
							}
						];

						componentObj.$( "setName", true );
						wireRequest.$(
							"getWireComponent",
							componentObj,
							false
						);
						wireRequest.hydrate();

						var passedArgs = componentObj.$callLog()[ "setName" ][ 1 ];
						expect( componentObj.$once( "setName" ) ).toBeTrue();
						expect( passedArgs[ 1 ] ).toBe( "George" );
					} );
				} );
			} );

			describe( "mount()", function(){
				it( "it calls mount() if it's defined on component", function(){
					componentObj.$( "mount", "sup?" );
					componentObj.$mount();
					expect( componentObj.$once( "mount" ) ).toBeTrue();
				} );

				it( "it should pass in the event, rc, and prc into mount()", function(){
					var rc = wireRequest.getCollection();

					rc[ "someRandomVar" ] = "someRandomValue";

					componentObj.$( "mount" );
					componentObj.$mount();

					var passedArgs = componentObj.$callLog().mount[ 1 ];

					expect( passedArgs.event ).toBeInstanceOf( "RequestContext" );
					expect( passedArgs.prc ).toBeStruct();
					expect( passedArgs.rc ).toBeStruct();
					expect( passedArgs.rc.someRandomVar ).toBe( "someRandomValue" );
				} );
			} );
		} );
	}

}
