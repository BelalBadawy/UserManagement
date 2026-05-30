/**
 * jQuery 4.0 Polyfill for Slick Carousel
 * Adds back removed methods that Slick 1.8.1 needs
 */

(function() {
    // Add $.type() back for Slick compatibility
    if (typeof jQuery !== 'undefined' && !jQuery.type) {
        jQuery.type = function(obj) {
            if (obj == null) {
                return obj + "";
            }

            // Support: Android <=2.3 only (functionish RegExp)
            return typeof obj === "object" || typeof obj === "function" ?
                class2type[Object.prototype.toString.call(obj)] || "object" :
                typeof obj;
        };

        var class2type = {};
        var toString = class2type.toString;

        // Populate the class2type map
        "Boolean Number String Function Array Date RegExp Object Error Symbol".split(" ").forEach(function(name) {
            class2type["[object " + name + "]"] = name.toLowerCase();
        });
    }

    // Add other removed methods if needed
    if (typeof jQuery !== 'undefined') {
        // $.isArray() - use Array.isArray()
        if (!jQuery.isArray) {
            jQuery.isArray = Array.isArray;
        }

        // $.isFunction()
        if (!jQuery.isFunction) {
            jQuery.isFunction = function(obj) {
                return typeof obj === "function";
            };
        }

        // $.isNumeric()
        if (!jQuery.isNumeric) {
            jQuery.isNumeric = function(obj) {
                var type = jQuery.type(obj);
                return (type === "number" || type === "string") &&
                    !isNaN(obj - parseFloat(obj));
            };
        }
    }

    console.log('[Polyfill] jQuery 4.0 compatibility methods added for Slick');
})();
