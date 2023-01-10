---
title: "[翻译]go interface"
date: 2020-05-06T22:20:18+08:00
featured_image: ""

categories:
- Go

tags:
- go runtime
---

## [译] Go Interface Values

> 原文 (https://www.airs.com/blog/archives/281)

## 原文翻译
虽然 Go 中interface 的指是灵活的，但它们也有令人困惑的方面。

接口值例如—-一个interface类型的变量—-包含其他类型的值。 interface类型被称为静态类型，因为这是编译器在编译期看到的类型。 另一种类型只在运行时可见，称为动态类型(dynamic type)。 根据定义，动态类型可以是任何除了interface的其他类型。

当通过赋值或函数调用复制一个 interface 值时，你是在复制动态类型里的值。 这通常是大多数类型通常的工作方式。 但是，使用 interface 的一个非常常见的情况是将动态类型作为指针使用。 在这种情况下，当你拷贝接口时，你拷贝的其实是指针，但是你不会拷贝指针指向的值。 在许多情况下，如果方法要更改值本身, 类型(type)的方法需要使用指针作为接收方(receiver)。 当 interface 必需的方法发生这种情况时，interface 实际上要求动态类型是指针类型。

这意味着，技术上来说虽然 interface 总是作为一个值拷贝，但在实际使用中，它们的行为常常好像是通过引用拷贝的。 也就是说，尽管没有显式标记，接口对象通常充当指针的角色。 这可能会让你困惑，直到你明白到底发生了什么。

在我上一篇文章中提到，对于 gccgo，一个 interface 总是包含一个指向值的指针。 现在我要纠正这个错误: 如果一个程序存储了包含了指针(或者unsafe.Pointer类型) 的 interface，那么存储在 interface 中的值就是指针本身。 也就是说，gccgo 不存储指向指针的指针(这需要分配堆空间来保存指针)。 这是一种自然的高效方法，因为实际上大多数接口对象都包含指针。

这种高效的方法贯穿于方法的实现。 方法总是接受指针作为接收方(receiver)参数。 如果方法的接收方(receiver)类型实际上不是指针，那么指针将隐式解引用，并在方法代码的开头复制值。 这意味着当在接口上调用方法时，存储在接口中的值可以直接传递给方法，而不管动态类型是否是指针。 (和上一篇文章一样，gc 编译器做的事情有些不同。)

### 补充
> 原文其实有点绕

> 如果 v 是一个 interface{}

什么是interface?

Interface 同时是两种东西

1. 一些方法的集合
2. 它自身也是一种类型

> interface{} type, the empty interface is the interface that has no methods.

由于没有 implements 关键字，所有类型都至少实现了empty interface， 这意味着，如果你编写一个将 interface{}作为参数的函数，则可以为该函数传任何值作为参数。
```go
func DoSomething(v interface{}) {
   // ...
}
```
令人困惑的地方在于

> 初学者倾向于相信“ v 是任何类型的” ，但这是错误的。
> v 不是任何类型的; 它是 interface{}类型的。

当向 DoSomething 函数传递一个值时，Go 运行时将执行类型转换(如果必要) ，并将该值转换为interface{}值。 所有值在运行时只有一种类型，而 v的静态类型是interface{}。

russ的说法
```go
type Stringer interface {
    String() string
}
```
接口值表示为包含两个单词的一对(单词)，

1. 指向存储在接口中的类型信息的指针
2. 指向相关数据的指针。

将 b 分配给 Stringer 类型的接口值会同时设置接口值的两个单词。

![interface](https://i.stack.imgur.com/H78Bz.png)

接口值中的第一个单词指向我所称的**interface table**或者 itable

Itable 以一些关于所涉及的类型的元数据开始，然后加上一个函数指针列表。 注意，itable 对应于 interface type，而不是动态类型。在我们的示例中,

Stringer 持有类型Binary的itable 列出了用于满足Stringer的方法，而后者只是“ String”：Binary的其他方法（“ Get”）未在“ itable” 中出现。

the itable for Stringer holding type Binary lists the methods used to satisfy Stringer, which is just String: Binary’s other methods (Get) make no appearance in the itable.

接口值中的第二个单词指向实际数据，在这种情况下为b的副本。
赋值var s Stringer = b 产生b的副本，而不是指向b的指针，原因与var c uint64 = b产生副本的原因相同：如果b以后发生变化，则s和c应该具有原始值，而不是新值。
存储在接口中的值可能任意大，但是只有一个字专用于在接口结构中保存该值，因此该分配在堆上分配了一块内存，并将指针记录在一个字槽中。

The second word in the interface value points at the actual data, in this case a copy of b.
The assignment var s Stringer = b makes a copy of b rather than point at b for the same reason that var c uint64 = b makes a copy: if b later changes, s and c are supposed to have the original value, not the new one.
Values stored in interfaces might be arbitrarily large, but only one word is dedicated to holding the value in the interface structure, so the assignment allocates a chunk of memory on the heap and records the pointer in the one-word slot.

## 参考
1. https://stackoverflow.com/questions/13511203/why-cant-i-assign-a-struct-to-an-interface
2. https://stackoverflow.com/questions/23148812/whats-the-meaning-of-interface/23148998#23148998
