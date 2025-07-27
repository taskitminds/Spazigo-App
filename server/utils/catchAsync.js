module.exports = fn => {
  return (req, res, next) => {
    fn(req, res, next).catch(next); // Catches any error and passes it to the next middleware (error handling)
  };
};
