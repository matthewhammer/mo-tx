import Array "mo:base/Array";
import Option "mo:base/Option";

module {
  public func empty<X>() : [X] { [] };

  // A smallish immutable set represented with an immutable array.
  public class ArraySet<X>(elements : [X], eq : (X, X) -> Bool) {
    public func array() : [X] { elements };

    public func has(x : X) : Bool {
      Option.isSome(Array.find<X>(elements, func(y : X) : Bool { eq(x, y) }));
    };

    public func add(x : X) : [X] {
      // to preserve set invariants (each element appears at most once),
      // this operation only makes sense after testing isMember and getting false.
      // we rely on the caller doing this.
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

    // Order does not matter.
    public func equals(ys : [X]) : Bool {
      let other = ArraySet(ys, eq);
      for (x in elements.vals()) {
        if (not (other.has(x))) { return false };
      };
      for (y in ys.vals()) {
        if (not (has(y))) { return false };
      };
      return true;
    };
  };

  public func principalSet(ps : [Principal]) : ArraySet<Principal> {
    ArraySet(
      ps,
      func(p1 : Principal, p2 : Principal) : Bool { p1 == p2 },
    );
  };

};
