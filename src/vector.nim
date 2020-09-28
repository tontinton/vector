import strformat
import math

const MINIMUM_VECTOR_LENGTH = 1
const DEFAULT_VECTOR_LENGTH = MINIMUM_VECTOR_LENGTH
const UNLIMITED_LENGTH = -1

type
    Vector*[T] = object
        memory: ptr T
        amount: int
        size: int
        maxAmount: int
        alive: bool

proc initVector*[T](length: int = DEFAULT_VECTOR_LENGTH, maxLength: int = UNLIMITED_LENGTH): Vector[T] =
    if 0 == T.sizeof():
        raise newException(ValueError, "cannot allocate a vector of a zero sized type")

    if UNLIMITED_LENGTH != maxLength and length > maxLength:
        raise newException(ValueError, fmt"cannot allocate a vector where length is bigger than max length")

    let memory = T.createU(toInt(toFloat(max(MINIMUM_VECTOR_LENGTH, length) * T.sizeof()).log(2).ceil()))
    if memory.isNil():
        raise newException(OutOfMemError, fmt"failed to allocate vector's memory of size {length}")

    Vector[T](memory: memory, amount: 0, size: length * T.sizeof(), maxAmount: maxLength, alive: true)

proc initVector*[T](items: seq[T]): Vector[T] =
    result = initVector[T](max(MINIMUM_VECTOR_LENGTH, items.len()))
    result.extend(items)

proc initVector*[T](items: Vector[T]): Vector[T] =
    result = initVector[T](max(MINIMUM_VECTOR_LENGTH, items.len()))
    result.extend(items)

proc `=destroy`*[T](vec: var Vector[T]) =
    #[
        Apparently it is not ok to check if a ptr is nil on destruction.
        The `alive` field is here to help us prevent the call of `=destroy` more than once
    ]#
    if not vec.alive:
        return

    vec.alive = false

    for i in 0..<vec.len():
        vec[i].`=destroy`()
    vec.clear()

    dealloc(vec.memory)
    vec.memory = nil

func len*[T](vec: Vector[T]): int =
    vec.amount

template getPtr*[T](vec: Vector[T], index: int): ptr T =
    if index >= vec.amount:
        raise newException(IndexError, "vector index out of range")
    cast[ptr T](cast[int](vec.memory) + index * T.sizeof())

template `[]`*[T](vec: Vector[T], index: int): var T =
    vec.getPtr(index)[]

proc reserveSlot[T](vec: var Vector[T]): ptr T =
    if UNLIMITED_LENGTH != vec.maxAmount and vec.amount + 1 > vec.maxAmount:
        raise newException(OverflowError, "cannot push more than the max length")

    if (vec.amount + 1) * T.sizeof() > vec.size:
        vec.size *= 2
        let newMemory = vec.memory.resize(vec.size)
        if newMemory.isNil():
            raise newException(OutOfMemError, fmt"failed to reallocate vector's memory of size {vec.size}")
        vec.memory = newMemory

    result = cast[ptr T](cast[int](vec.memory) + (vec.amount * T.sizeof()))
    inc(vec.amount)

template push*[T](vec: var Vector[T], item: T) =
    reserveSlot(vec)[] = item

proc pop*[T](vec: var Vector[T], index: int) =
    if index >= vec.amount:
        raise newException(IndexError, "vector index out of range")
    
    if index != vec.amount - 1:
        # Copy memory only if not last item
        let source = cast[pointer](cast[int](vec.memory) + ((index + 1) * T.sizeof()))
        let dest = cast[pointer](cast[int](vec.memory) + (index * T.sizeof()))
        let length = (vec.amount - index + 1) * T.sizeof()
        copyMem(dest, source, length)

    dec(vec.amount)

proc clear*[T](vec: var Vector[T]) =
    vec.amount = 0

proc resize[T](vec: var Vector[T], size: int) =
    vec.size = toInt(toFloat(size).log(2).ceil())
    let newMemory = vec.memory.resize(vec.size)
    if newMemory.isNil():
        raise newException(OutOfMemError, fmt"failed to reallocate vector's memory of size {vec.size}")
    vec.memory = newMemory

proc extend*[T](vec: var Vector[T], items: seq[T]) =
    let itemCount = items.len()
    if 0 == itemCount:
        return

    if UNLIMITED_LENGTH != vec.maxAmount and vec.amount + itemCount > vec.maxAmount:
        raise newException(OverflowError, "cannot extend more than the max length")

    let newSize = (vec.amount + itemCount) * T.sizeof()
    if newSize > vec.size:
        vec.resize(newSize)

    for item in items:
        copyMem(cast[pointer](cast[int](vec.memory) + (vec.amount * T.sizeof())), item.unsafeAddr, T.sizeof())
        inc(vec.amount)

proc extend*[T](vec: var Vector[T], items: Vector[T]) =
    let itemCount = items.amount
    if 0 == itemCount:
        return

    if UNLIMITED_LENGTH != vec.maxAmount and vec.amount + itemCount > vec.maxAmount:
        raise newException(OverflowError, "cannot extend more than the max length")

    let newSize = (vec.amount + itemCount) * T.sizeof()
    if newSize > vec.size:
        vec.resize(newSize)

    copyMem(cast[pointer](cast[int](vec.memory) + (vec.amount * T.sizeof())),
            items.memory,
            itemCount * T.sizeof())
    vec.amount += itemCount

iterator items*[T](vec: Vector[T]): T {.noSideEffect.} = 
    for i in 0..<vec.amount:
        yield vec[i]

iterator mitems*[T](vec: Vector[T]): var T {.noSideEffect.} = 
    for i in 0..<vec.amount:
        yield vec[i]

iterator pairs*[T](vec: Vector[T]): tuple[key: int, val: T] {.noSideEffect.} =
    for i in 0..<vec.amount:
        yield (i, vec[i])

iterator mpairs*[T](vec: Vector[T]): var tuple[key: int, val: T] {.noSideEffect.} =
    for i in 0..<vec.amount:
        yield (i, vec[i])

func `==`*[T](x, y: Vector[T]): bool =
    if x.len() != y.len():
        return false
    else:
        for i in 0..<x.amount:
            if x[i] != y[i]:
                return false
        return true

proc map*[A, B](vec: Vector[A], op: proc (x: A): B {.closure.}): Vector[B] =
    result = initVector[B](vec.amount)
    for i in 0..<vec.len():
        result.push(op(vec[i]))

func reprHelper[T](vec: Vector[T], result: var string) =
    result.add("[")
    for i in 0..<vec.len():
        if result.len > 1:
            result.add(", ")
        result.addQuoted(vec[i])
    result.add("]")

func `$`*[T](vec: Vector[T]): string =
    result = ""
    vec.reprHelper(result)
