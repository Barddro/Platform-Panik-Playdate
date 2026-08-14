Want to try and build a mature library to enable web-style ui creation


so for instance, we can create a button:

start_button = button()
start_button.on_press = function () ... end

we also want to enable a render tree per document, with automatic alignment  based on 'style' params
by default, button should auto wrap text size, but we can also pass parameters for explicit size, padding, etc.

by storing a 'dom' hierarchy for components, we can also easily deduce an order for button cycling (eg. which button do i highlight/target if i hit left/rigth)

after basic elements (text, button), we can support lists and a react-style 'map' where we can map table items to components

so, our document model looks like the following:

document = {
    component_tree = [list of (potentially nested) components]
}