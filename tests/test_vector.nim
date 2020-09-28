import unittest
import vector

type
    CountOnDestruct = object
        magic: int

var magic = 0

proc `=destroy`(x: var CountOnDestruct) =
    magic += x.magic

type
    ZeroLengthObj = object

suite "vector api tests":
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
            "[100, 1, 2, 3]" == $v

        expect IndexError:
            let _ = v[4]

        let v2 = initVector(@[1337, 420, 69])
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

        let v3 = initVector(v2)
        check:
            v2 == v3
            v2.getPtr(0) != v3.getPtr(0)

        let v4 = initVector(@[1338, 421, 70])
        check:
            v4 == v3.map(proc (x: auto): auto = x + 1)

        expect ValueError:
            let _ = initVector[ZeroLengthObj]()

    test "destruction":
        proc test_destruction() =
            var vec = initVector[CountOnDestruct](2)
            vec.push(CountOnDestruct(magic: 1))
            vec.push(CountOnDestruct(magic: 5))
            vec.push(CountOnDestruct(magic: 100))

        test_destruction()
        check(106 == magic)

        proc test_int_destruction_no_crash() =
            var vec = initVector[int]()
            vec.push(5)

        proc test_vector_of_vector_no_crash() =
            var vec = initVector[Vector[int]]()
            vec.push(initVector(@[1, 2, 3]))
            vec.push(initVector(@[7, 8, 9]))

        test_int_destruction_no_crash()
        test_vector_of_vector_no_crash()
        check(true)  # Did not crash

    test "max length":
        var v = initVector[int](maxLength=2)
        v.push(1)
        v.push(1)
        expect OverflowError:
            v.push(1)

        var v2 = initVector[int](maxLength=1)
        expect OverflowError:
            v2.extend(v)

        expect ValueError:
            var _ = initVector[uint8](length=10, maxLength=5)
