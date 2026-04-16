({
    loadBenefits : function(component) {
        const action = component.get("c.getCardBenefits");

        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);

            const state = response.getState();

            if (state === "SUCCESS") {
                component.set("v.benefits", response.getReturnValue());
                component.set("v.errorMessage", "");
            } else {
                let message = "Ocurrió un error al cargar los beneficios.";
                const errors = response.getError();

                if (errors && errors[0] && errors[0].message) {
                    message = errors[0].message;
                }

                component.set("v.errorMessage", message);
            }
        });

        $A.enqueueAction(action);
    }
})