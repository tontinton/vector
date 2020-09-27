import vector
import unittest

suite "vector tests":
    test "sanity":
        var v = initVector[int]()
        check(0 == v.len())

        v.push(100)
        check(100 == v[0])

        expect IndexError:
            let _ = v[1]

        v.extend(@[1, 2, 3])

        check:
            4 == v.len()
            1 == v[1]
            2 == v[2]
            3 == v[3]

        expect IndexError:
            let _ = v[4]

        let v2 = initVector[int](@[1337, 420, 69])
        check:
            3 == v2.len()
            1337 == v2[0]
            420 == v2[1]
            69 == v2[2]

        expect IndexError:
            let _ = v2[3]

        v.extend(v2)

        check:
            7 == v.len()
            1337 == v[4]

        v.pop(0)
        check:
            6 == v.len()
            1 == v[0]
            69 == v[5]

        expect IndexError:
            let _ = v[6]
            v.pop(6)

        v.clear()
        check:
            0 == v.len()
            3 == v2.len()

        expect IndexError:
            let _ = v[0]

        let v3 = initVector[int](v2)
        check(v2 == v3)
