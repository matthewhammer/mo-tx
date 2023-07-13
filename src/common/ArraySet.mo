import Array "mo:base/Array";
import Option "mo:base/Option";

module {
  public func empty<X>() : [X] { [] };

  // A smallish immutable set represented with an immutable array.
  public class ArraySet<X>(elements : [X], eq : (X, X) -> Bool) {
    public func array() : [X] { elements };

    public func isMember(x : X) : Bool {
      Option.isSome(Array.find<X>(elements, func(y : X) : Bool { eq(x, y) }));
    };

    public func add(x : X) : [X] {
      let size = elements.size();
      Array.tabulate<X>(
        size + 1,
        func i {
          if (i < size) {
            elements[i];
          } else {
            x;
          };
        },
      );
    };
  };

  public func principalSet(ps : [Principal]) : ArraySet<Principal> {
    ArraySet(
      ps,
      func(p1 : Principal, p2 : Principal) : Bool { p1 == p2 },
    );
  };

};
