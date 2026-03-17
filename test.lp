#include <a>.
#include "a.lp".
#program a(k).

#theory a {}.

not a(#inf, @f(1)).

not #false.

not #count {}.

a :- not b(d("asd")).

1 < 2.

#theory lp {
    lin_term {
    + : 0, binary, left;
    + : 1, binary, right;
    + : 2, unary
    };
    bounds{ };

    &op/0   : lin_term, any;
    &op/1   : lin_term, { <=, >=, <, >, !=, = }, bounds, any
}.

#script (python)
a = 1 + 1
#end.

&op{}.

#const a = 1.

a(X) :- b(X,_).

%* this is a comment *%
%this is a comment
