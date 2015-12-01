Meteor.startup(function(){
/* the function */
_.mixin({
    shallowDiff: function(a,b) {
        return _.omit(a, function(v,k) { return b[k] === v; })
    },
    diff: function(a,b) {
        var r = {};
        _.each(a, function(v,k) {
            if(b[k] === v) return;
            // but what if it returns an empty object? still attach?
            r[k] = _.isObject(v)
                    ? _.diff(v, b[k])
                    : v
                ;
            });
        return r;
    }
});
});