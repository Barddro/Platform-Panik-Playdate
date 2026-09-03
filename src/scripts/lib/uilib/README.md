Want to try and build a mature library to enable web-style ui creation


so for instance, we can create a button:

start_button = button()
start_button.on_press = function () ... end

we also want to enable a render tree per document, with automatic alignment  based on 'style' params
by default, button should auto wrap text size, but we can also pass parameters for explicit size, padding, etc.

we let components be able to be marked 'selectable' (and maybe down the line other custom traits). This way, we can allow custom behaviour for selected (eg. bob up and down in sinusoidal, render triangle pointer next to selected item, etc.)

by storing a 'dom' hierarchy for components, we can also easily deduce an order for button cycling for selectable components (eg. which button do i highlight/target if i hit left/rigth)

after basic elements (text, button), we can support lists and a react-style 'map' where we can map table items to components

so, our document model looks like the following:

document = {
    component_tree = [list of (potentially nested) components]
}

