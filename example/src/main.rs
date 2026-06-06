use example::{add, divide, multiply, subtract, Calculator};

fn main() {
    println!("=== Basic Calculator Demo ===\n");

    // Basic operations
    println!("Addition: 5 + 3 = {}", add(5, 3));
    println!("Subtraction: 5 - 3 = {}", subtract(5, 3));
    println!("Multiplication: 5 * 3 = {}", multiply(5, 3));

    match divide(10, 2) {
        Some(result) => println!("Division: 10 / 2 = {}", result),
        None => println!("Division: Cannot divide by zero"),
    }

    match divide(10, 0) {
        Some(result) => println!("Division: 10 / 0 = {}", result),
        None => println!("Division: 10 / 0 = Error (division by zero)"),
    }

    // Calculator with memory
    println!("\n=== Calculator with Memory ===\n");
    let mut calc = Calculator::new();
    println!("Initial memory: {}", calc.get_memory());

    calc.add_to_memory(100);
    println!("After adding 100: {}", calc.get_memory());

    calc.add_to_memory(50);
    println!("After adding 50: {}", calc.get_memory());

    calc.add_to_memory(-30);
    println!("After adding -30: {}", calc.get_memory());

    calc.clear_memory();
    println!("After clearing: {}", calc.get_memory());

    println!("\n=== Done! ===");
}
