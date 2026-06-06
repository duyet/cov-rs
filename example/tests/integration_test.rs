use example::{add, divide, multiply, subtract, Calculator};

#[test]
fn test_basic_arithmetic() {
    assert_eq!(add(10, 5), 15);
    assert_eq!(subtract(10, 5), 5);
    assert_eq!(multiply(10, 5), 50);
    assert_eq!(divide(10, 5), Some(2));
}

#[test]
fn test_edge_cases() {
    // Test zero
    assert_eq!(add(0, 0), 0);
    assert_eq!(multiply(0, 100), 0);
    assert_eq!(divide(0, 1), Some(0));

    // Test negative numbers
    assert_eq!(add(-5, -3), -8);
    assert_eq!(subtract(-5, -3), -2);
    assert_eq!(multiply(-5, -3), 15);
    assert_eq!(divide(-10, 2), Some(-5));
}

#[test]
fn test_division_by_zero() {
    assert_eq!(divide(1, 0), None);
    assert_eq!(divide(100, 0), None);
    assert_eq!(divide(-5, 0), None);
}

#[test]
fn test_calculator_workflow() {
    let mut calc = Calculator::new();

    // Start with 0
    assert_eq!(calc.get_memory(), 0);

    // Add some values
    calc.add_to_memory(100);
    calc.add_to_memory(50);
    calc.add_to_memory(25);
    assert_eq!(calc.get_memory(), 175);

    // Set to specific value
    calc.set_memory(1000);
    assert_eq!(calc.get_memory(), 1000);

    // Clear
    calc.clear_memory();
    assert_eq!(calc.get_memory(), 0);
}

#[test]
fn test_calculator_clone() {
    let mut calc1 = Calculator::new();
    calc1.set_memory(42);

    let calc2 = calc1.clone();
    assert_eq!(calc1.get_memory(), calc2.get_memory());
}

#[test]
fn test_calculator_equality() {
    let mut calc1 = Calculator::new();
    let mut calc2 = Calculator::new();

    assert_eq!(calc1, calc2);

    calc1.set_memory(100);
    assert_ne!(calc1, calc2);

    calc2.set_memory(100);
    assert_eq!(calc1, calc2);
}

#[test]
fn test_calculator_default() {
    let calc1 = Calculator::new();
    let calc2 = Calculator::default();

    assert_eq!(calc1, calc2);
}
