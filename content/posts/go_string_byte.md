---
title: "go string to byte"
date: 2020-05-31T21:30:28+08:00
featured_image: ""

categories:
- Go

tags:
- go runtime
- 翻译
---

## 0x01 背景
最近在review其他同学代码发现将 string转[]byte的时候，得到的[]byte的容量是会变的, 比如如下一段代码的输出是32

<!--more-->

```go
func main() {
	s1 := "abc"
	fmt.Println(cap([]byte(s1)))
}
```
## 0x02 探究
那么这是为什么呢，首先看汇编
> -N 禁止优化
> -S 输出汇编代码
> -l 禁止内联
```go
go build -gcflags="-N -l -S" go.go
```
得到以下代码

```
"".main STEXT size=293 args=0x0 locals=0xc0
	0x0000 00000 (/home/xxx/go.go:5)	TEXT	"".main(SB), ABIInternal, $192-0
	0x0000 00000 (/home/xxx/go.go:5)	MOVQ	(TLS), CX
	0x0009 00009 (/home/xxx/go.go:5)	LEAQ	-64(SP), AX
	0x000e 00014 (/home/xxx/go.go:5)	CMPQ	AX, 16(CX)
	0x0012 00018 (/home/xxx/go.go:5)	JLS	283
	0x0018 00024 (/home/xxx/go.go:5)	SUBQ	$192, SP
	0x001f 00031 (/home/xxx/go.go:5)	MOVQ	BP, 184(SP)
	0x0027 00039 (/home/xxx/go.go:5)	LEAQ	184(SP), BP
	0x002f 00047 (/home/xxx/go.go:5)	FUNCDATA	$0, gclocals·7d2d5fca80364273fb07d5820a76fef4(SB)
	0x002f 00047 (/home/xxx/go.go:5)	FUNCDATA	$1, gclocals·4dc9e0f0c3406fbbbbd2ec99068e8282(SB)
	0x002f 00047 (/home/xxx/go.go:5)	FUNCDATA	$2, gclocals·8dcadbff7c52509cfe2d26e4d7d24689(SB)
	0x002f 00047 (/home/xxx/go.go:5)	FUNCDATA	$3, "".main.stkobj(SB)
	0x002f 00047 (/home/xxx/go.go:6)	PCDATA	$0, $1
	0x002f 00047 (/home/xxx/go.go:6)	PCDATA	$1, $0
	0x002f 00047 (/home/xxx/go.go:6)	LEAQ	go.string."abc"(SB), AX
	0x0036 00054 (/home/xxx/go.go:6)	MOVQ	AX, "".s1+104(SP)
	0x003b 00059 (/home/xxx/go.go:6)	MOVQ	$3, "".s1+112(SP)
	0x0044 00068 (/home/xxx/go.go:7)	PCDATA	$0, $2
	0x0044 00068 (/home/xxx/go.go:7)	LEAQ	""..autotmp_4+56(SP), CX
	0x0049 00073 (/home/xxx/go.go:7)	PCDATA	$0, $1
	0x0049 00073 (/home/xxx/go.go:7)	MOVQ	CX, (SP)
	0x004d 00077 (/home/xxx/go.go:7)	PCDATA	$0, $0
	0x004d 00077 (/home/xxx/go.go:7)	MOVQ	AX, 8(SP)
	0x0052 00082 (/home/xxx/go.go:7)	MOVQ	$3, 16(SP)
	0x005b 00091 (/home/xxx/go.go:7)	CALL	runtime.stringtoslicebyte(SB)
	0x0060 00096 (/home/xxx/go.go:7)	MOVQ	40(SP), AX
	0x0065 00101 (/home/xxx/go.go:7)	MOVQ	32(SP), CX
	0x006a 00106 (/home/xxx/go.go:7)	PCDATA	$0, $3
	0x006a 00106 (/home/xxx/go.go:7)	MOVQ	24(SP), DX
	0x006f 00111 (/home/xxx/go.go:7)	PCDATA	$0, $0
	0x006f 00111 (/home/xxx/go.go:7)	MOVQ	DX, ""..autotmp_2+160(SP)
	0x0077 00119 (/home/xxx/go.go:7)	MOVQ	CX, ""..autotmp_2+168(SP)
	0x007f 00127 (/home/xxx/go.go:7)	MOVQ	AX, ""..autotmp_2+176(SP)
	0x0087 00135 (/home/xxx/go.go:7)	MOVQ	AX, ""..autotmp_3+48(SP)
	0x008c 00140 (/home/xxx/go.go:7)	MOVQ	AX, (SP)
	0x0090 00144 (/home/xxx/go.go:7)	CALL	runtime.convT64(SB)
	0x0095 00149 (/home/xxx/go.go:7)	PCDATA	$0, $1
	0x0095 00149 (/home/xxx/go.go:7)	MOVQ	8(SP), AX
	0x009a 00154 (/home/xxx/go.go:7)	PCDATA	$0, $0
	0x009a 00154 (/home/xxx/go.go:7)	PCDATA	$1, $1
	0x009a 00154 (/home/xxx/go.go:7)	MOVQ	AX, ""..autotmp_5+96(SP)
	0x009f 00159 (/home/xxx/go.go:7)	PCDATA	$1, $2
	0x009f 00159 (/home/xxx/go.go:7)	XORPS	X0, X0
	0x00a2 00162 (/home/xxx/go.go:7)	MOVUPS	X0, ""..autotmp_1+120(SP)
	0x00a7 00167 (/home/xxx/go.go:7)	PCDATA	$0, $1
	0x00a7 00167 (/home/xxx/go.go:7)	PCDATA	$1, $1
	0x00a7 00167 (/home/xxx/go.go:7)	LEAQ	""..autotmp_1+120(SP), AX
	0x00ac 00172 (/home/xxx/go.go:7)	MOVQ	AX, ""..autotmp_7+88(SP)
	0x00b1 00177 (/home/xxx/go.go:7)	TESTB	AL, (AX)
	0x00b3 00179 (/home/xxx/go.go:7)	PCDATA	$0, $2
	0x00b3 00179 (/home/xxx/go.go:7)	PCDATA	$1, $0
	0x00b3 00179 (/home/xxx/go.go:7)	MOVQ	""..autotmp_5+96(SP), CX
	0x00b8 00184 (/home/xxx/go.go:7)	PCDATA	$0, $4
	0x00b8 00184 (/home/xxx/go.go:7)	LEAQ	type.int(SB), DX
	0x00bf 00191 (/home/xxx/go.go:7)	PCDATA	$0, $2
	0x00bf 00191 (/home/xxx/go.go:7)	MOVQ	DX, ""..autotmp_1+120(SP)
	0x00c4 00196 (/home/xxx/go.go:7)	PCDATA	$0, $1
	0x00c4 00196 (/home/xxx/go.go:7)	MOVQ	CX, ""..autotmp_1+128(SP)
	0x00cc 00204 (/home/xxx/go.go:7)	TESTB	AL, (AX)
	0x00ce 00206 (/home/xxx/go.go:7)	JMP	208
	0x00d0 00208 (/home/xxx/go.go:7)	MOVQ	AX, ""..autotmp_6+136(SP)
	0x00d8 00216 (/home/xxx/go.go:7)	MOVQ	$1, ""..autotmp_6+144(SP)
	0x00e4 00228 (/home/xxx/go.go:7)	MOVQ	$1, ""..autotmp_6+152(SP)
	0x00f0 00240 (/home/xxx/go.go:7)	PCDATA	$0, $0
	0x00f0 00240 (/home/xxx/go.go:7)	MOVQ	AX, (SP)
	0x00f4 00244 (/home/xxx/go.go:7)	MOVQ	$1, 8(SP)
	0x00fd 00253 (/home/xxx/go.go:7)	MOVQ	$1, 16(SP)
	0x0106 00262 (/home/xxx/go.go:7)	CALL	fmt.Println(SB)
	0x010b 00267 (/home/xxx/go.go:9)	MOVQ	184(SP), BP
	0x0113 00275 (/home/xxx/go.go:9)	ADDQ	$192, SP
	0x011a 00282 (/home/xxx/go.go:9)	RET
	0x011b 00283 (/home/xxx/go.go:9)	NOP
	0x011b 00283 (/home/xxx/go.go:5)	PCDATA	$1, $-1
	0x011b 00283 (/home/xxx/go.go:5)	PCDATA	$0, $-1
	0x011b 00283 (/home/xxx/go.go:5)	CALL	runtime.morestack_noctxt(SB)
	0x0120 00288 (/home/xxx/go.go:5)	JMP	0
```

声明部分
```
"".main STEXT size=293 args=0x0 locals=0xc0
	0x0000 00000 (/home/xxx/go.go:5)	TEXT	"".main(SB), ABIInternal, $192-0
	0x0000 00000 (/home/xxx/go.go:5)	MOVQ	(TLS), CX
	0x0009 00009 (/home/xxx/go.go:5)	LEAQ	-64(SP), AX
	0x000e 00014 (/home/xxx/go.go:5)	CMPQ	AX, 16(CX)
	0x0012 00018 (/home/xxx/go.go:5)	JLS	283
	0x0018 00024 (/home/xxx/go.go:5)	SUBQ	$192, SP
	0x001f 00031 (/home/xxx/go.go:5)	MOVQ	BP, 184(SP)
	0x0027 00039 (/home/xxx/go.go:5)	LEAQ	184(SP), BP
```

main函数声明
```
0x0000 00000 (/home/xxx/go.go:3)	TEXT	"".main(SB), ABIInternal, $192-0
```

1. “”.main(被链接之后名字会变成main.main) 是一个全局的函数符号，存储在.text` 段中，该函数的地址是相对于整个地址空间起始位置的一个固定的偏移量。
2. $192-0 它分配了 192 字节的栈帧，且不接收参数，不返回值。$192-0 中的 192 代表局部变量字节数总和，-0 代表在 192 的地址基础上空出0的长度作为传入和返回对象, 即没有参数和返回值
```
0x0000 00000 (/home/xxx/go.go:3)	MOVQ	(TLS), CX
```
1. TLS 是一个由 runtime 维护的虚拟寄存器，保存了指向当前 g 的指针，这个 g 的数据结构会跟踪 goroutine 运行时的所有状态值
2. 将当前 *g 保存到 CX
```
0x0009 00009 (/home/xxx/go.go:3)	CMPQ	SP, 16(CX)
```
看一看 runtime 源代码中对于 g 的定义:

```go
type g struct {
	stack       stack   // 16 bytes
	// stackguard0 is the stack pointer compared in the Go stack growth prologue.
	// It is stack.lo+StackGuard normally, but can be StackPreempt to trigger a preemption.
	stackguard0 uintptr
	stackguard1 uintptr
```

我们可以看到 16(CX) 对应的是 g.stackguard0，是 runtime 维护的一个阈值，该值会被拿来与栈指针(stack-pointer)进行比较以判断一个 goroutine 是否马上要用完当前的栈空间。
```
0x0012 00018 (/home/xxx/go.go:5)	JLS	283
jumps to 283 if SP <= g.stackguard0

0x0018 00024 (/home/xxx/go.go:5)	SUBQ	$192, SP
```
main 作为调用者，通过对虚拟栈指针(stack-pointer)寄存器做减法，将其栈帧大小增加了 192 个字节(回忆一下栈是向低地址方向增长，所以这里的 SUBQ 指令是将栈帧的大小调整得更大了)。
```
0x001f 00031 (/home/xxx/go.go:5)	MOVQ	BP, 184(SP)
```
8 个字节(183(SP)-192(SP)) 用来存储当前帧指针 BP (这是一个实际存在的寄存器)的值，以支持栈的展开和方便调试
```
0x0027 00039 (/home/xxx/go.go:5)	LEAQ	184(SP), BP
```
跟着栈的增长，LEAQ 指令计算出帧指针的新地址，并将其存储到 BP 寄存器中。

### 看下字符串处理部分
```
0x002f 00047 (/Users/fancivez/tmp/go.go:6)	LEAQ	go.string."abc"(SB), AX
0x0036 00054 (/Users/fancivez/tmp/go.go:6)	MOVQ	AX, "".s1+104(SP)
0x003b 00059 (/Users/fancivez/tmp/go.go:6)	MOVQ	$3, "".s1+112(SP)
0x0044 00068 (/Users/fancivez/tmp/go.go:7)	PCDATA	$0, $2
0x0044 00068 (/Users/fancivez/tmp/go.go:7)	LEAQ	""..autotmp_4+56(SP), CX
0x0049 00073 (/Users/fancivez/tmp/go.go:7)	PCDATA	$0, $1
0x0049 00073 (/Users/fancivez/tmp/go.go:7)	MOVQ	CX, (SP)
0x004d 00077 (/Users/fancivez/tmp/go.go:7)	PCDATA	$0, $0
0x004d 00077 (/Users/fancivez/tmp/go.go:7)	MOVQ	AX, 8(SP)
0x0052 00082 (/Users/fancivez/tmp/go.go:7)	MOVQ	$3, 16(SP)
0x005b 00091 (/Users/fancivez/tmp/go.go:7)	CALL	runtime.stringtoslicebyte(SB)
0x002f 00047 (/Users/fancivez/tmp/go.go:6)	LEAQ	go.string."abc"(SB), AX
```

取字面值的地址,(字面值的数据在.data区域分配)

```
0x0036 00054 (/Users/fancivez/tmp/go.go:6)	MOVQ	AX, "".s1+104(SP)
```
将数据地址移动到栈指针104字节位置
```
0x003b 00059 (/Users/fancivez/tmp/go.go:6)	MOVQ	$3, "".s1+112(SP)
```
把字符串长度(3)移动到112字节位置

```
0x005b 00091 (/Users/fancivez/tmp/go.go:7)	CALL	runtime.stringtoslicebyte(SB)
```
## 参考
1. https://xargin.com/go-and-plan9-asm/
2. https://golang.org/doc/asm
3. https://www.youtube.com/watch?v=KINIAgRpkDA
4. https://www.cnblogs.com/yjf512/p/6132868.html