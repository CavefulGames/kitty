function inspect(value, opts) {
    // Default options
    const ctx = {
      budget: {},
      indentationLvl: 0,
      seen: [],
      currentDepth: 0,
      stylize: stylizeNoColor,
      showHidden: inspectDefaultOptions.showHidden,
      depth: inspectDefaultOptions.depth,
      colors: inspectDefaultOptions.colors,
      customInspect: inspectDefaultOptions.customInspect,
      showProxy: inspectDefaultOptions.showProxy,
      maxArrayLength: inspectDefaultOptions.maxArrayLength,
      maxStringLength: inspectDefaultOptions.maxStringLength,
      breakLength: inspectDefaultOptions.breakLength,
      compact: inspectDefaultOptions.compact,
      sorted: inspectDefaultOptions.sorted,
      getters: inspectDefaultOptions.getters,
      numericSeparator: inspectDefaultOptions.numericSeparator,
    };
    if (arguments.length > 1) {
      // Legacy...
      if (arguments.length > 2) {
        if (arguments[2] !== undefined) {
          ctx.depth = arguments[2];
        }
        if (arguments.length > 3 && arguments[3] !== undefined) {
          ctx.colors = arguments[3];
        }
      }
      // Set user-specified options
      if (typeof opts === 'boolean') {
        ctx.showHidden = opts;
      } else if (opts) {
        const optKeys = ObjectKeys(opts);
        for (let i = 0; i < optKeys.length; ++i) {
          const key = optKeys[i];
          // TODO(BridgeAR): Find a solution what to do about stylize. Either make
          // this function public or add a new API with a similar or better
          // functionality.
          if (
            ObjectPrototypeHasOwnProperty(inspectDefaultOptions, key) ||
            key === 'stylize') {
            ctx[key] = opts[key];
          } else if (ctx.userOptions === undefined) {
            // This is required to pass through the actual user input.
            ctx.userOptions = opts;
          }
        }
      }
    }
    if (ctx.colors) ctx.stylize = stylizeWithColor;
    if (ctx.maxArrayLength === null) ctx.maxArrayLength = Infinity;
    if (ctx.maxStringLength === null) ctx.maxStringLength = Infinity;
    return formatValue(ctx, value, 0);
  }
  inspect.custom = customInspectSymbol;
  
  ObjectDefineProperty(inspect, 'defaultOptions', {
    __proto__: null,
    get() {
      return inspectDefaultOptions;
    },
    set(options) {
      validateObject(options, 'options');
      return ObjectAssign(inspectDefaultOptions, options);
    },
  });
  