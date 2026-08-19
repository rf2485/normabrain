function custom_func_6dd4d16bdf4ed1710039e90773d6de7b(value) { try { 
  const trueLabel = '<span style="display: inline-block; margin: 1px; width: 2em; height: 2em; line-height: 2em; font-size: 1em; font-weight: bold; color: white; background-color: rgb(31, 119, 180); border-radius: 0.4em; text-align: center;">+</span>';
  const falseLabel = '<span style="display: inline-block; margin: 1px; width: 2em; height: 2em; line-height: 2em; font-size: 1em; font-weight: bold; color: white; background-color: rgb(214, 39, 40); border-radius: 0.4em; text-align: center;">-</span>';
  if (value === "True") {
      return trueLabel;
  } else if (value === "False") {
      return falseLabel;
  } else {
      return value;
  }
 } catch (e) { datavzrd.custom_error(e, 'outliers_removed') }}
function custom_func_86b25e41df2781abc44b20fdfea7e604(value, row) { try { 
  return value
    .trim()
    .split(/\s+/)
    .map(v => ({ data: Number(v) }));
   } catch (e) { datavzrd.custom_error(e, 'data') }}
