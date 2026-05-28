wit_bindgen::generate!({
    world: "calculator",
    path: "calculator.wit",
});

struct Component;

impl Guest for Component {
    fn add(a: i32, b: i32) -> i32 { a + b }
    fn sub(a: i32, b: i32) -> i32 { a - b }
}

export!(Component);
