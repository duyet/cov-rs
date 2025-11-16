/// Adds two numbers together.
///
/// # Examples
///
/// ```
/// assert_eq!(example::add(1, 2), 3);
/// assert_eq!(example::add(-1, 1), 0);
/// assert_eq!(example::add(0, 0), 0);
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

/// Subtracts the second number from the first.
///
/// # Examples
///
/// ```
/// assert_eq!(example::subtract(5, 3), 2);
/// assert_eq!(example::subtract(0, 5), -5);
/// ```
pub fn subtract(a: i32, b: i32) -> i32 {
    a - b
}

/// Multiplies two numbers.
///
/// # Examples
///
/// ```
/// assert_eq!(example::multiply(4, 5), 20);
/// assert_eq!(example::multiply(0, 100), 0);
/// ```
pub fn multiply(a: i32, b: i32) -> i32 {
    a * b
}

/// Divides the first number by the second.
///
/// # Examples
///
/// ```
/// assert_eq!(example::divide(10, 2), Some(5));
/// assert_eq!(example::divide(7, 2), Some(3));
/// assert_eq!(example::divide(10, 0), None);
/// ```
pub fn divide(a: i32, b: i32) -> Option<i32> {
    if b == 0 {
        None
    } else {
        Some(a / b)
    }
}

/// A simple calculator that can perform basic operations.
#[derive(Debug, Clone, PartialEq)]
pub struct Calculator {
    memory: i32,
}

impl Calculator {
    /// Creates a new calculator with memory initialized to 0.
    ///
    /// # Examples
    ///
    /// ```
    /// let calc = example::Calculator::new();
    /// assert_eq!(calc.get_memory(), 0);
    /// ```
    pub fn new() -> Self {
        Self { memory: 0 }
    }

    /// Gets the current value in memory.
    pub fn get_memory(&self) -> i32 {
        self.memory
    }

    /// Sets the memory to a specific value.
    pub fn set_memory(&mut self, value: i32) {
        self.memory = value;
    }

    /// Adds a value to memory.
    pub fn add_to_memory(&mut self, value: i32) {
        self.memory = add(self.memory, value);
    }

    /// Clears the memory (sets it to 0).
    pub fn clear_memory(&mut self) {
        self.memory = 0;
    }
}

impl Default for Calculator {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
        assert_eq!(add(-1, 1), 0);
        assert_eq!(add(0, 0), 0);
        assert_eq!(add(i32::MAX, 0), i32::MAX);
    }

    #[test]
    fn test_subtract() {
        assert_eq!(subtract(5, 3), 2);
        assert_eq!(subtract(3, 5), -2);
        assert_eq!(subtract(0, 0), 0);
        assert_eq!(subtract(10, -5), 15);
    }

    #[test]
    fn test_multiply() {
        assert_eq!(multiply(4, 5), 20);
        assert_eq!(multiply(0, 100), 0);
        assert_eq!(multiply(-2, 3), -6);
        assert_eq!(multiply(-2, -3), 6);
    }

    #[test]
    fn test_divide() {
        assert_eq!(divide(10, 2), Some(5));
        assert_eq!(divide(7, 2), Some(3));
        assert_eq!(divide(0, 5), Some(0));
        assert_eq!(divide(10, 0), None);
        assert_eq!(divide(-10, 2), Some(-5));
    }

    #[test]
    fn test_calculator_new() {
        let calc = Calculator::new();
        assert_eq!(calc.get_memory(), 0);
    }

    #[test]
    fn test_calculator_default() {
        let calc = Calculator::default();
        assert_eq!(calc.get_memory(), 0);
    }

    #[test]
    fn test_calculator_set_memory() {
        let mut calc = Calculator::new();
        calc.set_memory(42);
        assert_eq!(calc.get_memory(), 42);
    }

    #[test]
    fn test_calculator_add_to_memory() {
        let mut calc = Calculator::new();
        calc.set_memory(10);
        calc.add_to_memory(5);
        assert_eq!(calc.get_memory(), 15);
    }

    #[test]
    fn test_calculator_clear_memory() {
        let mut calc = Calculator::new();
        calc.set_memory(100);
        calc.clear_memory();
        assert_eq!(calc.get_memory(), 0);
    }

    #[test]
    fn test_calculator_chain_operations() {
        let mut calc = Calculator::new();
        calc.add_to_memory(10);
        calc.add_to_memory(20);
        calc.add_to_memory(-5);
        assert_eq!(calc.get_memory(), 25);
    }
}
