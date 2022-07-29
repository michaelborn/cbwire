component {

    property name="cbwireRequest" inject="CBWireRequest@cbwire";

    function onCBWireHydrate( event, rc, prc, data ){

        var cbwireComponent = data.component;

		var engine = cbwireComponent.getEngine();

        if ( variables.cbwireRequest.hasFingerprint() ) {
			cbwireComponent.getEngine().setId( variables.cbwireRequest.getFingerPrint()[ "id" ] );
		}

		engine.setBeforeHydrationState( duplicate( engine.getState() ) );

		// Invoke '$preHydrate' event
		engine.invokeMethod( "$preHydrate" );

		if ( variables.cbwireRequest.hasData() ) {
			cbwireComponent.setData( variables.cbwireRequest.getData() );
		}

		// Check if our request contains a server memo, and if so update our component state.
		if ( variables.cbwireRequest.hasServerMemo() ) {
			var serverMemo = variables.cbwireRequest.getServerMemo();

			serverMemo.data.each( function( key, value ){
				// Call the setter method
				engine.invokeMethod(
					methodName = "set" & arguments.key,
					value      = isNull( arguments.value ) ? "" : arguments.value
				);
			} );

			if ( variables.cbwireRequest.hasChildren() ) {
				variables.$children = variables.cbwireRequest.getChildren();
			}
		}

		// Check if our request contains updates, and if so apply them.
		if ( variables.cbwireRequest.hasUpdates() ) {
			variables.cbwireRequest.applyUpdates( cbwireComponent );
		}

		// Invoke '$postHydrate' event
		engine.invokeMethod( "$postHydrate" );
    }
}