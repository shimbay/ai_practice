; ModuleID = 'LLVMDialectModule'
source_filename = "LLVMDialectModule"

@global_smem = external addrspace(3) global [0 x i8], align 16

define void @matmul_split_k_kernel(ptr addrspace(1) %0, ptr addrspace(1) %1, ptr addrspace(1) %2, i32 %3, i32 %4, i32 %5, i32 %6, i32 %7, i32 %8) local_unnamed_addr !dbg !7 {
  %10 = tail call i32 asm "mov.u32 $0, %ctaid.x;", "=r"() #2, !dbg !10
  %11 = tail call i32 asm "mov.u32 $0, %ctaid.y;", "=r"() #2, !dbg !11
  %12 = tail call i32 asm "mov.u32 $0, %ctaid.z;", "=r"() #2, !dbg !12
  %13 = shl i32 %11, 6, !dbg !13
  %14 = insertelement <2 x i32> poison, i32 %3, i64 0, !dbg !14
  %15 = insertelement <2 x i32> %14, i32 %5, i64 1, !dbg !14
  %16 = sext i32 %6 to i64, !dbg !14
  %17 = sext i32 %7 to i64, !dbg !15
  %18 = tail call i32 @llvm.nvvm.read.ptx.sreg.tid.x(), !dbg !16
  %19 = and i32 %18, 31, !dbg !16
  %20 = lshr i32 %18, 5, !dbg !16
  %21 = lshr i32 %18, 3, !dbg !16
  %22 = lshr i32 %18, 4, !dbg !16
  %23 = shl i32 %18, 2, !dbg !16
  %24 = and i32 %23, 4, !dbg !16
  %25 = insertelement <2 x i32> poison, i32 %10, i64 0, !dbg !17
  %26 = insertelement <2 x i32> %25, i32 %12, i64 1, !dbg !17
  %27 = shl <2 x i32> %26, <i32 6, i32 5>, !dbg !17
  %28 = insertelement <2 x i32> poison, i32 %21, i64 0, !dbg !16
  %29 = insertelement <2 x i32> %28, i32 %23, i64 1, !dbg !16
  %30 = and <2 x i32> %29, <i32 15, i32 28>, !dbg !16
  %31 = extractelement <2 x i32> %30, i64 0, !dbg !16
  %32 = or disjoint i32 %31, 16, !dbg !16
  %33 = or disjoint i32 %31, 32, !dbg !16
  %34 = or disjoint i32 %31, 48, !dbg !16
  %35 = zext nneg i32 %32 to i64
  %36 = zext nneg i32 %33 to i64
  %37 = zext nneg i32 %34 to i64
  %38 = extractelement <2 x i32> %27, i64 0, !dbg !16
  %39 = sext i32 %38 to i64, !dbg !16
  %40 = or disjoint i64 %39, %35, !dbg !16
  %41 = or disjoint i64 %39, %36, !dbg !16
  %42 = or disjoint i64 %39, %37, !dbg !16
  %43 = or disjoint <2 x i32> %27, %30, !dbg !16
  %44 = extractelement <2 x i32> %43, i64 0, !dbg !16
  %45 = sext i32 %44 to i64, !dbg !16
  %46 = mul nsw i64 %45, %16, !dbg !16
  %47 = mul nsw i64 %40, %16, !dbg !16
  %48 = mul nsw i64 %41, %16, !dbg !16
  %49 = mul nsw i64 %42, %16, !dbg !16
  %50 = getelementptr float, ptr addrspace(1) %0, i64 %46, !dbg !16
  %51 = extractelement <2 x i32> %43, i64 1, !dbg !16
  %52 = sext i32 %51 to i64, !dbg !16
  %53 = getelementptr float, ptr addrspace(1) %50, i64 %52, !dbg !16
  %54 = getelementptr float, ptr addrspace(1) %0, i64 %47, !dbg !16
  %55 = getelementptr float, ptr addrspace(1) %54, i64 %52, !dbg !16
  %56 = getelementptr float, ptr addrspace(1) %0, i64 %48, !dbg !16
  %57 = getelementptr float, ptr addrspace(1) %56, i64 %52, !dbg !16
  %58 = getelementptr float, ptr addrspace(1) %0, i64 %49, !dbg !16
  %59 = getelementptr float, ptr addrspace(1) %58, i64 %52, !dbg !16
  %60 = icmp sgt i64 %40, -1, !dbg !16
  %61 = icmp sgt i64 %41, -1, !dbg !16
  %62 = icmp sgt i64 %42, -1, !dbg !16
  %63 = sext i32 %3 to i64, !dbg !16
  %64 = icmp slt i64 %40, %63, !dbg !16
  %65 = icmp slt i64 %41, %63, !dbg !16
  %66 = icmp slt i64 %42, %63, !dbg !16
  %67 = and i1 %60, %64, !dbg !16
  %68 = and i1 %61, %65, !dbg !16
  %69 = and i1 %62, %66, !dbg !16
  %70 = icmp sgt <2 x i32> %27, <i32 -1, i32 -1>, !dbg !16
  %71 = icmp slt <2 x i32> %43, %15, !dbg !16
  %72 = and <2 x i1> %70, %71, !dbg !16
  %73 = extractelement <2 x i1> %72, i64 0, !dbg !16
  %74 = extractelement <2 x i1> %72, i64 1, !dbg !16
  %75 = and i1 %73, %74, !dbg !16
  %76 = and i1 %67, %74, !dbg !16
  %77 = and i1 %68, %74, !dbg !16
  %78 = and i1 %69, %74, !dbg !16
  %79 = tail call { i32, i32, i32, i32 } asm sideeffect "mov.u32 $0, 0x0;\0A\09mov.u32 $1, 0x0;\0A\09mov.u32 $2, 0x0;\0A\09mov.u32 $3, 0x0;\0A\09@$5 ld.global.v4.b32 { $0, $1, $2, $3 }, [ $4 + 0 ];\0A\09@!$7 mov.u32 $0, $6;\0A\09@!$9 mov.u32 $1, $8;\0A\09@!$11 mov.u32 $2, $10;\0A\09@!$13 mov.u32 $3, $12;", "=r,=r,=r,=r,l,b,r,b,r,b,r,b,r,b"(ptr addrspace(1) %53, i1 %75, i32 0, i1 %75, i32 0, i1 %75, i32 0, i1 %75, i32 0, i1 %75) #2, !dbg !16
  %80 = extractvalue { i32, i32, i32, i32 } %79, 0, !dbg !16
  %81 = extractvalue { i32, i32, i32, i32 } %79, 1, !dbg !16
  %82 = extractvalue { i32, i32, i32, i32 } %79, 2, !dbg !16
  %83 = extractvalue { i32, i32, i32, i32 } %79, 3, !dbg !16
  %84 = tail call { i32, i32, i32, i32 } asm sideeffect "mov.u32 $0, 0x0;\0A\09mov.u32 $1, 0x0;\0A\09mov.u32 $2, 0x0;\0A\09mov.u32 $3, 0x0;\0A\09@$5 ld.global.v4.b32 { $0, $1, $2, $3 }, [ $4 + 0 ];\0A\09@!$7 mov.u32 $0, $6;\0A\09@!$9 mov.u32 $1, $8;\0A\09@!$11 mov.u32 $2, $10;\0A\09@!$13 mov.u32 $3, $12;", "=r,=r,=r,=r,l,b,r,b,r,b,r,b,r,b"(ptr addrspace(1) %55, i1 %76, i32 0, i1 %76, i32 0, i1 %76, i32 0, i1 %76, i32 0, i1 %76) #2, !dbg !16
  %85 = extractvalue { i32, i32, i32, i32 } %84, 0, !dbg !16
  %86 = extractvalue { i32, i32, i32, i32 } %84, 1, !dbg !16
  %87 = extractvalue { i32, i32, i32, i32 } %84, 2, !dbg !16
  %88 = extractvalue { i32, i32, i32, i32 } %84, 3, !dbg !16
  %89 = tail call { i32, i32, i32, i32 } asm sideeffect "mov.u32 $0, 0x0;\0A\09mov.u32 $1, 0x0;\0A\09mov.u32 $2, 0x0;\0A\09mov.u32 $3, 0x0;\0A\09@$5 ld.global.v4.b32 { $0, $1, $2, $3 }, [ $4 + 0 ];\0A\09@!$7 mov.u32 $0, $6;\0A\09@!$9 mov.u32 $1, $8;\0A\09@!$11 mov.u32 $2, $10;\0A\09@!$13 mov.u32 $3, $12;", "=r,=r,=r,=r,l,b,r,b,r,b,r,b,r,b"(ptr addrspace(1) %57, i1 %77, i32 0, i1 %77, i32 0, i1 %77, i32 0, i1 %77, i32 0, i1 %77) #2, !dbg !16
  %90 = extractvalue { i32, i32, i32, i32 } %89, 0, !dbg !16
  %91 = extractvalue { i32, i32, i32, i32 } %89, 1, !dbg !16
  %92 = extractvalue { i32, i32, i32, i32 } %89, 2, !dbg !16
  %93 = extractvalue { i32, i32, i32, i32 } %89, 3, !dbg !16
  %94 = tail call { i32, i32, i32, i32 } asm sideeffect "mov.u32 $0, 0x0;\0A\09mov.u32 $1, 0x0;\0A\09mov.u32 $2, 0x0;\0A\09mov.u32 $3, 0x0;\0A\09@$5 ld.global.v4.b32 { $0, $1, $2, $3 }, [ $4 + 0 ];\0A\09@!$7 mov.u32 $0, $6;\0A\09@!$9 mov.u32 $1, $8;\0A\09@!$11 mov.u32 $2, $10;\0A\09@!$13 mov.u32 $3, $12;", "=r,=r,=r,=r,l,b,r,b,r,b,r,b,r,b"(ptr addrspace(1) %59, i1 %78, i32 0, i1 %78, i32 0, i1 %78, i32 0, i1 %78, i32 0, i1 %78) #2, !dbg !16
  %95 = extractvalue { i32, i32, i32, i32 } %94, 0, !dbg !16
  %96 = extractvalue { i32, i32, i32, i32 } %94, 1, !dbg !16
  %97 = extractvalue { i32, i32, i32, i32 } %94, 2, !dbg !16
  %98 = extractvalue { i32, i32, i32, i32 } %94, 3, !dbg !16
  %99 = shl nuw nsw i32 %31, 5, !dbg !16
  %100 = lshr i32 %18, 1, !dbg !16
  %101 = xor i32 %23, %100, !dbg !16
  %102 = and i32 %101, 28, !dbg !16
  %103 = or disjoint i32 %99, %102, !dbg !16
  %104 = zext nneg i32 %103 to i64, !dbg !16
  %105 = getelementptr float, ptr addrspace(3) @global_smem, i64 %104, !dbg !16
  %106 = shl nuw nsw i32 %32, 5, !dbg !16
  %107 = or disjoint i32 %106, %102, !dbg !16
  %108 = zext nneg i32 %107 to i64, !dbg !16
  %109 = getelementptr float, ptr addrspace(3) @global_smem, i64 %108, !dbg !16
  %110 = shl nuw nsw i32 %33, 5, !dbg !16
  %111 = or disjoint i32 %110, %102, !dbg !16
  %112 = zext nneg i32 %111 to i64, !dbg !16
  %113 = getelementptr float, ptr addrspace(3) @global_smem, i64 %112, !dbg !16
  %114 = shl nuw nsw i32 %34, 5, !dbg !16
  %115 = or disjoint i32 %114, %102, !dbg !16
  %116 = zext nneg i32 %115 to i64, !dbg !16
  %117 = getelementptr float, ptr addrspace(3) @global_smem, i64 %116, !dbg !16
  %118 = insertelement <4 x i32> poison, i32 %80, i64 0, !dbg !16
  %119 = insertelement <4 x i32> %118, i32 %81, i64 1, !dbg !16
  %120 = insertelement <4 x i32> %119, i32 %82, i64 2, !dbg !16
  %121 = insertelement <4 x i32> %120, i32 %83, i64 3, !dbg !16
  store <4 x i32> %121, ptr addrspace(3) %105, align 16, !dbg !16
  %122 = insertelement <4 x i32> poison, i32 %85, i64 0, !dbg !16
  %123 = insertelement <4 x i32> %122, i32 %86, i64 1, !dbg !16
  %124 = insertelement <4 x i32> %123, i32 %87, i64 2, !dbg !16
  %125 = insertelement <4 x i32> %124, i32 %88, i64 3, !dbg !16
  store <4 x i32> %125, ptr addrspace(3) %109, align 16, !dbg !16
  %126 = insertelement <4 x i32> poison, i32 %90, i64 0, !dbg !16
  %127 = insertelement <4 x i32> %126, i32 %91, i64 1, !dbg !16
  %128 = insertelement <4 x i32> %127, i32 %92, i64 2, !dbg !16
  %129 = insertelement <4 x i32> %128, i32 %93, i64 3, !dbg !16
  store <4 x i32> %129, ptr addrspace(3) %113, align 16, !dbg !16
  %130 = insertelement <4 x i32> poison, i32 %95, i64 0, !dbg !16
  %131 = insertelement <4 x i32> %130, i32 %96, i64 1, !dbg !16
  %132 = insertelement <4 x i32> %131, i32 %97, i64 2, !dbg !16
  %133 = insertelement <4 x i32> %132, i32 %98, i64 3, !dbg !16
  store <4 x i32> %133, ptr addrspace(3) %117, align 16, !dbg !16
  %134 = insertelement <2 x i32> poison, i32 %23, i64 0, !dbg !16
  %135 = insertelement <2 x i32> %134, i32 %22, i64 1, !dbg !16
  %136 = and <2 x i32> %135, <i32 60, i32 7>, !dbg !16
  %137 = extractelement <2 x i32> %136, i64 1, !dbg !18
  %138 = or disjoint i32 %137, 8, !dbg !16
  %139 = or disjoint i32 %137, 16, !dbg !16
  %140 = or disjoint i32 %137, 24, !dbg !16
  %141 = zext nneg i32 %138 to i64
  %142 = zext nneg i32 %139 to i64
  %143 = zext nneg i32 %140 to i64
  %144 = insertelement <2 x i32> %27, i32 %13, i64 0, !dbg !15
  %145 = extractelement <2 x i32> %27, i64 1, !dbg !16
  %146 = sext i32 %145 to i64, !dbg !16
  %147 = or disjoint i64 %146, %141, !dbg !16
  %148 = or disjoint i64 %146, %142, !dbg !16
  %149 = or disjoint i64 %146, %143, !dbg !16
  %150 = or disjoint <2 x i32> %144, %136, !dbg !18
  %151 = extractelement <2 x i32> %150, i64 1, !dbg !18
  %152 = sext i32 %151 to i64, !dbg !18
  %153 = mul nsw i64 %152, %17, !dbg !18
  %154 = mul nsw i64 %147, %17, !dbg !18
  %155 = mul nsw i64 %148, %17, !dbg !18
  %156 = mul nsw i64 %149, %17, !dbg !18
  %157 = getelementptr float, ptr addrspace(1) %1, i64 %153, !dbg !18
  %158 = extractelement <2 x i32> %150, i64 0, !dbg !18
  %159 = sext i32 %158 to i64, !dbg !18
  %160 = getelementptr float, ptr addrspace(1) %157, i64 %159, !dbg !18
  %161 = getelementptr float, ptr addrspace(1) %1, i64 %154, !dbg !18
  %162 = getelementptr float, ptr addrspace(1) %161, i64 %159, !dbg !18
  %163 = getelementptr float, ptr addrspace(1) %1, i64 %155, !dbg !18
  %164 = getelementptr float, ptr addrspace(1) %163, i64 %159, !dbg !18
  %165 = getelementptr float, ptr addrspace(1) %1, i64 %156, !dbg !18
  %166 = getelementptr float, ptr addrspace(1) %165, i64 %159, !dbg !18
  %167 = icmp sgt i64 %147, -1, !dbg !18
  %168 = icmp sgt i64 %148, -1, !dbg !18
  %169 = icmp sgt i64 %149, -1, !dbg !18
  %170 = insertelement <2 x i32> %15, i32 %4, i64 0, !dbg !15
  %171 = sext i32 %5 to i64, !dbg !18
  %172 = icmp slt i64 %147, %171, !dbg !18
  %173 = icmp slt i64 %148, %171, !dbg !18
  %174 = icmp slt i64 %149, %171, !dbg !18
  %175 = and i1 %167, %172, !dbg !18
  %176 = and i1 %168, %173, !dbg !18
  %177 = and i1 %169, %174, !dbg !18
  %178 = icmp sgt <2 x i32> %144, <i32 -1, i32 -1>, !dbg !18
  %179 = icmp slt <2 x i32> %150, %170, !dbg !18
  %180 = and <2 x i1> %178, %179, !dbg !18
  %181 = extractelement <2 x i1> %180, i64 0, !dbg !18
  %182 = extractelement <2 x i1> %180, i64 1, !dbg !18
  %183 = and i1 %181, %182, !dbg !18
  %184 = and i1 %181, %175, !dbg !18
  %185 = and i1 %181, %176, !dbg !18
  %186 = and i1 %181, %177, !dbg !18
  %187 = tail call { i32, i32, i32, i32 } asm sideeffect "mov.u32 $0, 0x0;\0A\09mov.u32 $1, 0x0;\0A\09mov.u32 $2, 0x0;\0A\09mov.u32 $3, 0x0;\0A\09@$5 ld.global.v4.b32 { $0, $1, $2, $3 }, [ $4 + 0 ];\0A\09@!$7 mov.u32 $0, $6;\0A\09@!$9 mov.u32 $1, $8;\0A\09@!$11 mov.u32 $2, $10;\0A\09@!$13 mov.u32 $3, $12;", "=r,=r,=r,=r,l,b,r,b,r,b,r,b,r,b"(ptr addrspace(1) %160, i1 %183, i32 0, i1 %183, i32 0, i1 %183, i32 0, i1 %183, i32 0, i1 %183) #2, !dbg !18
  %188 = extractvalue { i32, i32, i32, i32 } %187, 0, !dbg !18
  %189 = extractvalue { i32, i32, i32, i32 } %187, 1, !dbg !18
  %190 = extractvalue { i32, i32, i32, i32 } %187, 2, !dbg !18
  %191 = extractvalue { i32, i32, i32, i32 } %187, 3, !dbg !18
  %192 = tail call { i32, i32, i32, i32 } asm sideeffect "mov.u32 $0, 0x0;\0A\09mov.u32 $1, 0x0;\0A\09mov.u32 $2, 0x0;\0A\09mov.u32 $3, 0x0;\0A\09@$5 ld.global.v4.b32 { $0, $1, $2, $3 }, [ $4 + 0 ];\0A\09@!$7 mov.u32 $0, $6;\0A\09@!$9 mov.u32 $1, $8;\0A\09@!$11 mov.u32 $2, $10;\0A\09@!$13 mov.u32 $3, $12;", "=r,=r,=r,=r,l,b,r,b,r,b,r,b,r,b"(ptr addrspace(1) %162, i1 %184, i32 0, i1 %184, i32 0, i1 %184, i32 0, i1 %184, i32 0, i1 %184) #2, !dbg !18
  %193 = extractvalue { i32, i32, i32, i32 } %192, 0, !dbg !18
  %194 = extractvalue { i32, i32, i32, i32 } %192, 1, !dbg !18
  %195 = extractvalue { i32, i32, i32, i32 } %192, 2, !dbg !18
  %196 = extractvalue { i32, i32, i32, i32 } %192, 3, !dbg !18
  %197 = tail call { i32, i32, i32, i32 } asm sideeffect "mov.u32 $0, 0x0;\0A\09mov.u32 $1, 0x0;\0A\09mov.u32 $2, 0x0;\0A\09mov.u32 $3, 0x0;\0A\09@$5 ld.global.v4.b32 { $0, $1, $2, $3 }, [ $4 + 0 ];\0A\09@!$7 mov.u32 $0, $6;\0A\09@!$9 mov.u32 $1, $8;\0A\09@!$11 mov.u32 $2, $10;\0A\09@!$13 mov.u32 $3, $12;", "=r,=r,=r,=r,l,b,r,b,r,b,r,b,r,b"(ptr addrspace(1) %164, i1 %185, i32 0, i1 %185, i32 0, i1 %185, i32 0, i1 %185, i32 0, i1 %185) #2, !dbg !18
  %198 = extractvalue { i32, i32, i32, i32 } %197, 0, !dbg !18
  %199 = extractvalue { i32, i32, i32, i32 } %197, 1, !dbg !18
  %200 = extractvalue { i32, i32, i32, i32 } %197, 2, !dbg !18
  %201 = extractvalue { i32, i32, i32, i32 } %197, 3, !dbg !18
  %202 = tail call { i32, i32, i32, i32 } asm sideeffect "mov.u32 $0, 0x0;\0A\09mov.u32 $1, 0x0;\0A\09mov.u32 $2, 0x0;\0A\09mov.u32 $3, 0x0;\0A\09@$5 ld.global.v4.b32 { $0, $1, $2, $3 }, [ $4 + 0 ];\0A\09@!$7 mov.u32 $0, $6;\0A\09@!$9 mov.u32 $1, $8;\0A\09@!$11 mov.u32 $2, $10;\0A\09@!$13 mov.u32 $3, $12;", "=r,=r,=r,=r,l,b,r,b,r,b,r,b,r,b"(ptr addrspace(1) %166, i1 %186, i32 0, i1 %186, i32 0, i1 %186, i32 0, i1 %186, i32 0, i1 %186) #2, !dbg !18
  %203 = extractvalue { i32, i32, i32, i32 } %202, 0, !dbg !18
  %204 = extractvalue { i32, i32, i32, i32 } %202, 1, !dbg !18
  %205 = extractvalue { i32, i32, i32, i32 } %202, 2, !dbg !18
  %206 = extractvalue { i32, i32, i32, i32 } %202, 3, !dbg !18
  %207 = shl nuw nsw i32 %137, 6, !dbg !18
  %208 = shl nuw nsw i32 %22, 3, !dbg !18
  %209 = and i32 %208, 24, !dbg !18
  %.masked = and i32 %23, 56, !dbg !18
  %210 = xor i32 %.masked, %209, !dbg !18
  %211 = or disjoint i32 %210, %24, !dbg !18
  %212 = or disjoint i32 %211, %207, !dbg !18
  %213 = zext nneg i32 %212 to i64, !dbg !18
  %214 = getelementptr float, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i64 8192), i64 %213, !dbg !18
  %215 = shl nuw nsw i32 %138, 6, !dbg !18
  %216 = or disjoint i32 %215, %211, !dbg !18
  %217 = zext nneg i32 %216 to i64, !dbg !18
  %218 = getelementptr float, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i64 8192), i64 %217, !dbg !18
  %219 = shl nuw nsw i32 %139, 6, !dbg !18
  %220 = or disjoint i32 %219, %211, !dbg !18
  %221 = zext nneg i32 %220 to i64, !dbg !18
  %222 = getelementptr float, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i64 8192), i64 %221, !dbg !18
  %223 = shl nuw nsw i32 %140, 6, !dbg !18
  %224 = or disjoint i32 %223, %211, !dbg !18
  %225 = zext nneg i32 %224 to i64, !dbg !18
  %226 = getelementptr float, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i64 8192), i64 %225, !dbg !18
  %227 = insertelement <4 x i32> poison, i32 %188, i64 0, !dbg !18
  %228 = insertelement <4 x i32> %227, i32 %189, i64 1, !dbg !18
  %229 = insertelement <4 x i32> %228, i32 %190, i64 2, !dbg !18
  %230 = insertelement <4 x i32> %229, i32 %191, i64 3, !dbg !18
  store <4 x i32> %230, ptr addrspace(3) %214, align 16, !dbg !18
  %231 = insertelement <4 x i32> poison, i32 %193, i64 0, !dbg !18
  %232 = insertelement <4 x i32> %231, i32 %194, i64 1, !dbg !18
  %233 = insertelement <4 x i32> %232, i32 %195, i64 2, !dbg !18
  %234 = insertelement <4 x i32> %233, i32 %196, i64 3, !dbg !18
  store <4 x i32> %234, ptr addrspace(3) %218, align 16, !dbg !18
  %235 = insertelement <4 x i32> poison, i32 %198, i64 0, !dbg !18
  %236 = insertelement <4 x i32> %235, i32 %199, i64 1, !dbg !18
  %237 = insertelement <4 x i32> %236, i32 %200, i64 2, !dbg !18
  %238 = insertelement <4 x i32> %237, i32 %201, i64 3, !dbg !18
  store <4 x i32> %238, ptr addrspace(3) %222, align 16, !dbg !18
  %239 = insertelement <4 x i32> poison, i32 %203, i64 0, !dbg !18
  %240 = insertelement <4 x i32> %239, i32 %204, i64 1, !dbg !18
  %241 = insertelement <4 x i32> %240, i32 %205, i64 2, !dbg !18
  %242 = insertelement <4 x i32> %241, i32 %206, i64 3, !dbg !18
  store <4 x i32> %242, ptr addrspace(3) %226, align 16, !dbg !18
  tail call void @llvm.nvvm.barrier0(), !dbg !16
  %243 = and i32 %18, 7, !dbg !16
  %244 = lshr i32 %19, 4, !dbg !16
  %245 = lshr i32 %18, 2, !dbg !16
  %246 = and i32 %245, 16, !dbg !16
  %247 = and i32 %18, 15, !dbg !16
  %248 = or disjoint i32 %247, %246, !dbg !16
  %249 = xor i32 %244, %243, !dbg !16
  %250 = shl nuw nsw i32 %248, 5, !dbg !16
  %251 = shl nuw nsw i32 %249, 2, !dbg !16
  %252 = or disjoint i32 %250, %251, !dbg !16
  %253 = zext nneg i32 %252 to i64, !dbg !16
  %254 = getelementptr float, ptr addrspace(3) @global_smem, i64 %253, !dbg !16
  %255 = tail call { i32, i32, i32, i32 } asm sideeffect "ldmatrix.sync.aligned.m8n8.x4.shared.b16 { $0, $1, $2, $3 }, [ $4 + 0 ];", "=r,=r,=r,=r,r"(ptr addrspace(3) %254) #2, !dbg !16
  %256 = extractvalue { i32, i32, i32, i32 } %255, 0, !dbg !16
  %257 = extractvalue { i32, i32, i32, i32 } %255, 1, !dbg !16
  %258 = extractvalue { i32, i32, i32, i32 } %255, 2, !dbg !16
  %259 = extractvalue { i32, i32, i32, i32 } %255, 3, !dbg !16
  %260 = or disjoint i32 %244, 2, !dbg !16
  %261 = xor i32 %260, %243, !dbg !16
  %262 = shl nuw nsw i32 %261, 2, !dbg !16
  %263 = or disjoint i32 %262, %250, !dbg !16
  %264 = zext nneg i32 %263 to i64, !dbg !16
  %265 = getelementptr float, ptr addrspace(3) @global_smem, i64 %264, !dbg !16
  %266 = tail call { i32, i32, i32, i32 } asm sideeffect "ldmatrix.sync.aligned.m8n8.x4.shared.b16 { $0, $1, $2, $3 }, [ $4 + 0 ];", "=r,=r,=r,=r,r"(ptr addrspace(3) %265) #2, !dbg !16
  %267 = extractvalue { i32, i32, i32, i32 } %266, 0, !dbg !16
  %268 = extractvalue { i32, i32, i32, i32 } %266, 1, !dbg !16
  %269 = extractvalue { i32, i32, i32, i32 } %266, 2, !dbg !16
  %270 = extractvalue { i32, i32, i32, i32 } %266, 3, !dbg !16
  %271 = or disjoint i32 %244, 4, !dbg !16
  %272 = xor i32 %271, %243, !dbg !16
  %273 = shl nuw nsw i32 %272, 2, !dbg !16
  %274 = or disjoint i32 %273, %250, !dbg !16
  %275 = zext nneg i32 %274 to i64, !dbg !16
  %276 = getelementptr float, ptr addrspace(3) @global_smem, i64 %275, !dbg !16
  %277 = tail call { i32, i32, i32, i32 } asm sideeffect "ldmatrix.sync.aligned.m8n8.x4.shared.b16 { $0, $1, $2, $3 }, [ $4 + 0 ];", "=r,=r,=r,=r,r"(ptr addrspace(3) %276) #2, !dbg !16
  %278 = extractvalue { i32, i32, i32, i32 } %277, 0, !dbg !16
  %279 = extractvalue { i32, i32, i32, i32 } %277, 1, !dbg !16
  %280 = extractvalue { i32, i32, i32, i32 } %277, 2, !dbg !16
  %281 = extractvalue { i32, i32, i32, i32 } %277, 3, !dbg !16
  %282 = or disjoint i32 %244, 6, !dbg !16
  %283 = xor i32 %282, %243, !dbg !16
  %284 = shl nuw nsw i32 %283, 2, !dbg !16
  %285 = or disjoint i32 %284, %250, !dbg !16
  %286 = zext nneg i32 %285 to i64, !dbg !16
  %287 = getelementptr float, ptr addrspace(3) @global_smem, i64 %286, !dbg !16
  %288 = tail call { i32, i32, i32, i32 } asm sideeffect "ldmatrix.sync.aligned.m8n8.x4.shared.b16 { $0, $1, $2, $3 }, [ $4 + 0 ];", "=r,=r,=r,=r,r"(ptr addrspace(3) %287) #2, !dbg !16
  %289 = extractvalue { i32, i32, i32, i32 } %288, 0, !dbg !16
  %290 = extractvalue { i32, i32, i32, i32 } %288, 1, !dbg !16
  %291 = extractvalue { i32, i32, i32, i32 } %288, 2, !dbg !16
  %292 = extractvalue { i32, i32, i32, i32 } %288, 3, !dbg !16
  %293 = getelementptr i8, ptr addrspace(3) %254, i64 4096, !dbg !16
  %294 = tail call { i32, i32, i32, i32 } asm sideeffect "ldmatrix.sync.aligned.m8n8.x4.shared.b16 { $0, $1, $2, $3 }, [ $4 + 0 ];", "=r,=r,=r,=r,r"(ptr addrspace(3) %293) #2, !dbg !16
  %295 = extractvalue { i32, i32, i32, i32 } %294, 0, !dbg !16
  %296 = extractvalue { i32, i32, i32, i32 } %294, 1, !dbg !16
  %297 = extractvalue { i32, i32, i32, i32 } %294, 2, !dbg !16
  %298 = extractvalue { i32, i32, i32, i32 } %294, 3, !dbg !16
  %299 = getelementptr i8, ptr addrspace(3) %265, i64 4096, !dbg !16
  %300 = tail call { i32, i32, i32, i32 } asm sideeffect "ldmatrix.sync.aligned.m8n8.x4.shared.b16 { $0, $1, $2, $3 }, [ $4 + 0 ];", "=r,=r,=r,=r,r"(ptr addrspace(3) %299) #2, !dbg !16
  %301 = extractvalue { i32, i32, i32, i32 } %300, 0, !dbg !16
  %302 = extractvalue { i32, i32, i32, i32 } %300, 1, !dbg !16
  %303 = extractvalue { i32, i32, i32, i32 } %300, 2, !dbg !16
  %304 = extractvalue { i32, i32, i32, i32 } %300, 3, !dbg !16
  %305 = getelementptr i8, ptr addrspace(3) %276, i64 4096, !dbg !16
  %306 = tail call { i32, i32, i32, i32 } asm sideeffect "ldmatrix.sync.aligned.m8n8.x4.shared.b16 { $0, $1, $2, $3 }, [ $4 + 0 ];", "=r,=r,=r,=r,r"(ptr addrspace(3) %305) #2, !dbg !16
  %307 = extractvalue { i32, i32, i32, i32 } %306, 0, !dbg !16
  %308 = extractvalue { i32, i32, i32, i32 } %306, 1, !dbg !16
  %309 = extractvalue { i32, i32, i32, i32 } %306, 2, !dbg !16
  %310 = extractvalue { i32, i32, i32, i32 } %306, 3, !dbg !16
  %311 = getelementptr i8, ptr addrspace(3) %287, i64 4096, !dbg !16
  %312 = tail call { i32, i32, i32, i32 } asm sideeffect "ldmatrix.sync.aligned.m8n8.x4.shared.b16 { $0, $1, $2, $3 }, [ $4 + 0 ];", "=r,=r,=r,=r,r"(ptr addrspace(3) %311) #2, !dbg !16
  %313 = extractvalue { i32, i32, i32, i32 } %312, 0, !dbg !16
  %314 = extractvalue { i32, i32, i32, i32 } %312, 1, !dbg !16
  %315 = extractvalue { i32, i32, i32, i32 } %312, 2, !dbg !16
  %316 = extractvalue { i32, i32, i32, i32 } %312, 3, !dbg !16
  %317 = and i32 %20, 1, !dbg !18
  %318 = lshr i32 %19, 2, !dbg !18
  %319 = and i32 %18, 3, !dbg !18
  %320 = xor i32 %317, %319, !dbg !18
  %321 = shl nuw nsw i32 %320, 3, !dbg !18
  %322 = or disjoint i32 %321, %318, !dbg !18
  %323 = shl nuw nsw i32 %319, 6, !dbg !18
  %324 = or disjoint i32 %322, %323, !dbg !18
  %325 = or disjoint i32 %317, 2, !dbg !18
  %326 = xor i32 %325, %319, !dbg !18
  %327 = shl nuw nsw i32 %326, 3, !dbg !18
  %328 = or disjoint i32 %327, %318, !dbg !18
  %329 = or disjoint i32 %328, %323, !dbg !18
  %330 = zext nneg i32 %324 to i64, !dbg !18
  %331 = getelementptr float, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i64 8192), i64 %330, !dbg !18
  %332 = zext nneg i32 %329 to i64, !dbg !18
  %333 = getelementptr float, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i64 8192), i64 %332, !dbg !18
  %334 = getelementptr i8, ptr addrspace(3) %331, i64 1024, !dbg !18
  %335 = getelementptr i8, ptr addrspace(3) %333, i64 1024, !dbg !18
  %336 = load i32, ptr addrspace(3) %331, align 4, !dbg !18
  %337 = load i32, ptr addrspace(3) %333, align 4, !dbg !18
  %338 = load i32, ptr addrspace(3) %334, align 4, !dbg !18
  %339 = load i32, ptr addrspace(3) %335, align 4, !dbg !18
  %340 = getelementptr i8, ptr addrspace(3) %331, i64 2048, !dbg !18
  %341 = getelementptr i8, ptr addrspace(3) %331, i64 3072, !dbg !18
  %342 = getelementptr i8, ptr addrspace(3) %333, i64 2048, !dbg !18
  %343 = getelementptr i8, ptr addrspace(3) %333, i64 3072, !dbg !18
  %344 = load i32, ptr addrspace(3) %340, align 4, !dbg !18
  %345 = load i32, ptr addrspace(3) %342, align 4, !dbg !18
  %346 = load i32, ptr addrspace(3) %341, align 4, !dbg !18
  %347 = load i32, ptr addrspace(3) %343, align 4, !dbg !18
  %348 = getelementptr i8, ptr addrspace(3) %331, i64 4096, !dbg !18
  %349 = getelementptr i8, ptr addrspace(3) %331, i64 5120, !dbg !18
  %350 = getelementptr i8, ptr addrspace(3) %333, i64 4096, !dbg !18
  %351 = getelementptr i8, ptr addrspace(3) %333, i64 5120, !dbg !18
  %352 = load i32, ptr addrspace(3) %348, align 4, !dbg !18
  %353 = load i32, ptr addrspace(3) %350, align 4, !dbg !18
  %354 = load i32, ptr addrspace(3) %349, align 4, !dbg !18
  %355 = load i32, ptr addrspace(3) %351, align 4, !dbg !18
  %356 = getelementptr i8, ptr addrspace(3) %331, i64 6144, !dbg !18
  %357 = getelementptr i8, ptr addrspace(3) %331, i64 7168, !dbg !18
  %358 = getelementptr i8, ptr addrspace(3) %333, i64 6144, !dbg !18
  %359 = getelementptr i8, ptr addrspace(3) %333, i64 7168, !dbg !18
  %360 = load i32, ptr addrspace(3) %356, align 4, !dbg !18
  %361 = load i32, ptr addrspace(3) %358, align 4, !dbg !18
  %362 = load i32, ptr addrspace(3) %357, align 4, !dbg !18
  %363 = load i32, ptr addrspace(3) %359, align 4, !dbg !18
  %364 = or disjoint i32 %317, 4, !dbg !18
  %365 = xor i32 %364, %319, !dbg !18
  %366 = shl nuw nsw i32 %365, 3, !dbg !18
  %367 = or disjoint i32 %366, %318, !dbg !18
  %368 = or disjoint i32 %367, %323, !dbg !18
  %369 = or disjoint i32 %317, 6, !dbg !18
  %370 = xor i32 %369, %319, !dbg !18
  %371 = shl nuw nsw i32 %370, 3, !dbg !18
  %372 = or disjoint i32 %371, %318, !dbg !18
  %373 = or disjoint i32 %372, %323, !dbg !18
  %374 = zext nneg i32 %368 to i64, !dbg !18
  %375 = getelementptr float, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i64 8192), i64 %374, !dbg !18
  %376 = zext nneg i32 %373 to i64, !dbg !18
  %377 = getelementptr float, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @global_smem, i64 8192), i64 %376, !dbg !18
  %378 = getelementptr i8, ptr addrspace(3) %375, i64 1024, !dbg !18
  %379 = getelementptr i8, ptr addrspace(3) %377, i64 1024, !dbg !18
  %380 = load i32, ptr addrspace(3) %375, align 4, !dbg !18
  %381 = load i32, ptr addrspace(3) %377, align 4, !dbg !18
  %382 = load i32, ptr addrspace(3) %378, align 4, !dbg !18
  %383 = load i32, ptr addrspace(3) %379, align 4, !dbg !18
  %384 = getelementptr i8, ptr addrspace(3) %375, i64 2048, !dbg !18
  %385 = getelementptr i8, ptr addrspace(3) %375, i64 3072, !dbg !18
  %386 = getelementptr i8, ptr addrspace(3) %377, i64 2048, !dbg !18
  %387 = getelementptr i8, ptr addrspace(3) %377, i64 3072, !dbg !18
  %388 = load i32, ptr addrspace(3) %384, align 4, !dbg !18
  %389 = load i32, ptr addrspace(3) %386, align 4, !dbg !18
  %390 = load i32, ptr addrspace(3) %385, align 4, !dbg !18
  %391 = load i32, ptr addrspace(3) %387, align 4, !dbg !18
  %392 = getelementptr i8, ptr addrspace(3) %375, i64 4096, !dbg !18
  %393 = getelementptr i8, ptr addrspace(3) %375, i64 5120, !dbg !18
  %394 = getelementptr i8, ptr addrspace(3) %377, i64 4096, !dbg !18
  %395 = getelementptr i8, ptr addrspace(3) %377, i64 5120, !dbg !18
  %396 = load i32, ptr addrspace(3) %392, align 4, !dbg !18
  %397 = load i32, ptr addrspace(3) %394, align 4, !dbg !18
  %398 = load i32, ptr addrspace(3) %393, align 4, !dbg !18
  %399 = load i32, ptr addrspace(3) %395, align 4, !dbg !18
  %400 = getelementptr i8, ptr addrspace(3) %375, i64 6144, !dbg !18
  %401 = getelementptr i8, ptr addrspace(3) %375, i64 7168, !dbg !18
  %402 = getelementptr i8, ptr addrspace(3) %377, i64 6144, !dbg !18
  %403 = getelementptr i8, ptr addrspace(3) %377, i64 7168, !dbg !18
  %404 = load i32, ptr addrspace(3) %400, align 4, !dbg !18
  %405 = load i32, ptr addrspace(3) %402, align 4, !dbg !18
  %406 = load i32, ptr addrspace(3) %401, align 4, !dbg !18
  %407 = load i32, ptr addrspace(3) %403, align 4, !dbg !18
  %408 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, i32 %256, i32 %257, i32 %258, i32 %259, i32 %336, i32 %338) #2, !dbg !19
  %409 = extractvalue { float, float, float, float } %408, 0, !dbg !19
  %410 = extractvalue { float, float, float, float } %408, 1, !dbg !19
  %411 = extractvalue { float, float, float, float } %408, 2, !dbg !19
  %412 = extractvalue { float, float, float, float } %408, 3, !dbg !19
  %413 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, i32 %256, i32 %257, i32 %258, i32 %259, i32 %337, i32 %339) #2, !dbg !19
  %414 = extractvalue { float, float, float, float } %413, 0, !dbg !19
  %415 = extractvalue { float, float, float, float } %413, 1, !dbg !19
  %416 = extractvalue { float, float, float, float } %413, 2, !dbg !19
  %417 = extractvalue { float, float, float, float } %413, 3, !dbg !19
  %418 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, i32 %256, i32 %257, i32 %258, i32 %259, i32 %380, i32 %382) #2, !dbg !19
  %419 = extractvalue { float, float, float, float } %418, 0, !dbg !19
  %420 = extractvalue { float, float, float, float } %418, 1, !dbg !19
  %421 = extractvalue { float, float, float, float } %418, 2, !dbg !19
  %422 = extractvalue { float, float, float, float } %418, 3, !dbg !19
  %423 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, i32 %256, i32 %257, i32 %258, i32 %259, i32 %381, i32 %383) #2, !dbg !19
  %424 = extractvalue { float, float, float, float } %423, 0, !dbg !19
  %425 = extractvalue { float, float, float, float } %423, 1, !dbg !19
  %426 = extractvalue { float, float, float, float } %423, 2, !dbg !19
  %427 = extractvalue { float, float, float, float } %423, 3, !dbg !19
  %428 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, i32 %295, i32 %296, i32 %297, i32 %298, i32 %336, i32 %338) #2, !dbg !19
  %429 = extractvalue { float, float, float, float } %428, 0, !dbg !19
  %430 = extractvalue { float, float, float, float } %428, 1, !dbg !19
  %431 = extractvalue { float, float, float, float } %428, 2, !dbg !19
  %432 = extractvalue { float, float, float, float } %428, 3, !dbg !19
  %433 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, i32 %295, i32 %296, i32 %297, i32 %298, i32 %337, i32 %339) #2, !dbg !19
  %434 = extractvalue { float, float, float, float } %433, 0, !dbg !19
  %435 = extractvalue { float, float, float, float } %433, 1, !dbg !19
  %436 = extractvalue { float, float, float, float } %433, 2, !dbg !19
  %437 = extractvalue { float, float, float, float } %433, 3, !dbg !19
  %438 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, i32 %295, i32 %296, i32 %297, i32 %298, i32 %380, i32 %382) #2, !dbg !19
  %439 = extractvalue { float, float, float, float } %438, 0, !dbg !19
  %440 = extractvalue { float, float, float, float } %438, 1, !dbg !19
  %441 = extractvalue { float, float, float, float } %438, 2, !dbg !19
  %442 = extractvalue { float, float, float, float } %438, 3, !dbg !19
  %443 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, float 0.000000e+00, i32 %295, i32 %296, i32 %297, i32 %298, i32 %381, i32 %383) #2, !dbg !19
  %444 = extractvalue { float, float, float, float } %443, 0, !dbg !19
  %445 = extractvalue { float, float, float, float } %443, 1, !dbg !19
  %446 = extractvalue { float, float, float, float } %443, 2, !dbg !19
  %447 = extractvalue { float, float, float, float } %443, 3, !dbg !19
  %448 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %409, float %410, float %411, float %412, i32 %267, i32 %268, i32 %269, i32 %270, i32 %344, i32 %346) #2, !dbg !19
  %449 = extractvalue { float, float, float, float } %448, 0, !dbg !19
  %450 = extractvalue { float, float, float, float } %448, 1, !dbg !19
  %451 = extractvalue { float, float, float, float } %448, 2, !dbg !19
  %452 = extractvalue { float, float, float, float } %448, 3, !dbg !19
  %453 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %414, float %415, float %416, float %417, i32 %267, i32 %268, i32 %269, i32 %270, i32 %345, i32 %347) #2, !dbg !19
  %454 = extractvalue { float, float, float, float } %453, 0, !dbg !19
  %455 = extractvalue { float, float, float, float } %453, 1, !dbg !19
  %456 = extractvalue { float, float, float, float } %453, 2, !dbg !19
  %457 = extractvalue { float, float, float, float } %453, 3, !dbg !19
  %458 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %419, float %420, float %421, float %422, i32 %267, i32 %268, i32 %269, i32 %270, i32 %388, i32 %390) #2, !dbg !19
  %459 = extractvalue { float, float, float, float } %458, 0, !dbg !19
  %460 = extractvalue { float, float, float, float } %458, 1, !dbg !19
  %461 = extractvalue { float, float, float, float } %458, 2, !dbg !19
  %462 = extractvalue { float, float, float, float } %458, 3, !dbg !19
  %463 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %424, float %425, float %426, float %427, i32 %267, i32 %268, i32 %269, i32 %270, i32 %389, i32 %391) #2, !dbg !19
  %464 = extractvalue { float, float, float, float } %463, 0, !dbg !19
  %465 = extractvalue { float, float, float, float } %463, 1, !dbg !19
  %466 = extractvalue { float, float, float, float } %463, 2, !dbg !19
  %467 = extractvalue { float, float, float, float } %463, 3, !dbg !19
  %468 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %429, float %430, float %431, float %432, i32 %301, i32 %302, i32 %303, i32 %304, i32 %344, i32 %346) #2, !dbg !19
  %469 = extractvalue { float, float, float, float } %468, 0, !dbg !19
  %470 = extractvalue { float, float, float, float } %468, 1, !dbg !19
  %471 = extractvalue { float, float, float, float } %468, 2, !dbg !19
  %472 = extractvalue { float, float, float, float } %468, 3, !dbg !19
  %473 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %434, float %435, float %436, float %437, i32 %301, i32 %302, i32 %303, i32 %304, i32 %345, i32 %347) #2, !dbg !19
  %474 = extractvalue { float, float, float, float } %473, 0, !dbg !19
  %475 = extractvalue { float, float, float, float } %473, 1, !dbg !19
  %476 = extractvalue { float, float, float, float } %473, 2, !dbg !19
  %477 = extractvalue { float, float, float, float } %473, 3, !dbg !19
  %478 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %439, float %440, float %441, float %442, i32 %301, i32 %302, i32 %303, i32 %304, i32 %388, i32 %390) #2, !dbg !19
  %479 = extractvalue { float, float, float, float } %478, 0, !dbg !19
  %480 = extractvalue { float, float, float, float } %478, 1, !dbg !19
  %481 = extractvalue { float, float, float, float } %478, 2, !dbg !19
  %482 = extractvalue { float, float, float, float } %478, 3, !dbg !19
  %483 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %444, float %445, float %446, float %447, i32 %301, i32 %302, i32 %303, i32 %304, i32 %389, i32 %391) #2, !dbg !19
  %484 = extractvalue { float, float, float, float } %483, 0, !dbg !19
  %485 = extractvalue { float, float, float, float } %483, 1, !dbg !19
  %486 = extractvalue { float, float, float, float } %483, 2, !dbg !19
  %487 = extractvalue { float, float, float, float } %483, 3, !dbg !19
  %488 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %449, float %450, float %451, float %452, i32 %278, i32 %279, i32 %280, i32 %281, i32 %352, i32 %354) #2, !dbg !19
  %489 = extractvalue { float, float, float, float } %488, 0, !dbg !19
  %490 = extractvalue { float, float, float, float } %488, 1, !dbg !19
  %491 = extractvalue { float, float, float, float } %488, 2, !dbg !19
  %492 = extractvalue { float, float, float, float } %488, 3, !dbg !19
  %493 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %454, float %455, float %456, float %457, i32 %278, i32 %279, i32 %280, i32 %281, i32 %353, i32 %355) #2, !dbg !19
  %494 = extractvalue { float, float, float, float } %493, 0, !dbg !19
  %495 = extractvalue { float, float, float, float } %493, 1, !dbg !19
  %496 = extractvalue { float, float, float, float } %493, 2, !dbg !19
  %497 = extractvalue { float, float, float, float } %493, 3, !dbg !19
  %498 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %459, float %460, float %461, float %462, i32 %278, i32 %279, i32 %280, i32 %281, i32 %396, i32 %398) #2, !dbg !19
  %499 = extractvalue { float, float, float, float } %498, 0, !dbg !19
  %500 = extractvalue { float, float, float, float } %498, 1, !dbg !19
  %501 = extractvalue { float, float, float, float } %498, 2, !dbg !19
  %502 = extractvalue { float, float, float, float } %498, 3, !dbg !19
  %503 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %464, float %465, float %466, float %467, i32 %278, i32 %279, i32 %280, i32 %281, i32 %397, i32 %399) #2, !dbg !19
  %504 = extractvalue { float, float, float, float } %503, 0, !dbg !19
  %505 = extractvalue { float, float, float, float } %503, 1, !dbg !19
  %506 = extractvalue { float, float, float, float } %503, 2, !dbg !19
  %507 = extractvalue { float, float, float, float } %503, 3, !dbg !19
  %508 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %469, float %470, float %471, float %472, i32 %307, i32 %308, i32 %309, i32 %310, i32 %352, i32 %354) #2, !dbg !19
  %509 = extractvalue { float, float, float, float } %508, 0, !dbg !19
  %510 = extractvalue { float, float, float, float } %508, 1, !dbg !19
  %511 = extractvalue { float, float, float, float } %508, 2, !dbg !19
  %512 = extractvalue { float, float, float, float } %508, 3, !dbg !19
  %513 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %474, float %475, float %476, float %477, i32 %307, i32 %308, i32 %309, i32 %310, i32 %353, i32 %355) #2, !dbg !19
  %514 = extractvalue { float, float, float, float } %513, 0, !dbg !19
  %515 = extractvalue { float, float, float, float } %513, 1, !dbg !19
  %516 = extractvalue { float, float, float, float } %513, 2, !dbg !19
  %517 = extractvalue { float, float, float, float } %513, 3, !dbg !19
  %518 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %479, float %480, float %481, float %482, i32 %307, i32 %308, i32 %309, i32 %310, i32 %396, i32 %398) #2, !dbg !19
  %519 = extractvalue { float, float, float, float } %518, 0, !dbg !19
  %520 = extractvalue { float, float, float, float } %518, 1, !dbg !19
  %521 = extractvalue { float, float, float, float } %518, 2, !dbg !19
  %522 = extractvalue { float, float, float, float } %518, 3, !dbg !19
  %523 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %484, float %485, float %486, float %487, i32 %307, i32 %308, i32 %309, i32 %310, i32 %397, i32 %399) #2, !dbg !19
  %524 = extractvalue { float, float, float, float } %523, 0, !dbg !19
  %525 = extractvalue { float, float, float, float } %523, 1, !dbg !19
  %526 = extractvalue { float, float, float, float } %523, 2, !dbg !19
  %527 = extractvalue { float, float, float, float } %523, 3, !dbg !19
  %528 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %489, float %490, float %491, float %492, i32 %289, i32 %290, i32 %291, i32 %292, i32 %360, i32 %362) #2, !dbg !19
  %529 = extractvalue { float, float, float, float } %528, 0, !dbg !19
  %530 = extractvalue { float, float, float, float } %528, 1, !dbg !19
  %531 = extractvalue { float, float, float, float } %528, 2, !dbg !19
  %532 = extractvalue { float, float, float, float } %528, 3, !dbg !19
  %533 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %494, float %495, float %496, float %497, i32 %289, i32 %290, i32 %291, i32 %292, i32 %361, i32 %363) #2, !dbg !19
  %534 = extractvalue { float, float, float, float } %533, 0, !dbg !19
  %535 = extractvalue { float, float, float, float } %533, 1, !dbg !19
  %536 = extractvalue { float, float, float, float } %533, 2, !dbg !19
  %537 = extractvalue { float, float, float, float } %533, 3, !dbg !19
  %538 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %499, float %500, float %501, float %502, i32 %289, i32 %290, i32 %291, i32 %292, i32 %404, i32 %406) #2, !dbg !19
  %539 = extractvalue { float, float, float, float } %538, 0, !dbg !19
  %540 = extractvalue { float, float, float, float } %538, 1, !dbg !19
  %541 = extractvalue { float, float, float, float } %538, 2, !dbg !19
  %542 = extractvalue { float, float, float, float } %538, 3, !dbg !19
  %543 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %504, float %505, float %506, float %507, i32 %289, i32 %290, i32 %291, i32 %292, i32 %405, i32 %407) #2, !dbg !19
  %544 = extractvalue { float, float, float, float } %543, 0, !dbg !19
  %545 = extractvalue { float, float, float, float } %543, 1, !dbg !19
  %546 = extractvalue { float, float, float, float } %543, 2, !dbg !19
  %547 = extractvalue { float, float, float, float } %543, 3, !dbg !19
  %548 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %509, float %510, float %511, float %512, i32 %313, i32 %314, i32 %315, i32 %316, i32 %360, i32 %362) #2, !dbg !19
  %549 = extractvalue { float, float, float, float } %548, 0, !dbg !19
  %550 = extractvalue { float, float, float, float } %548, 1, !dbg !19
  %551 = extractvalue { float, float, float, float } %548, 2, !dbg !19
  %552 = extractvalue { float, float, float, float } %548, 3, !dbg !19
  %553 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %514, float %515, float %516, float %517, i32 %313, i32 %314, i32 %315, i32 %316, i32 %361, i32 %363) #2, !dbg !19
  %554 = extractvalue { float, float, float, float } %553, 0, !dbg !19
  %555 = extractvalue { float, float, float, float } %553, 1, !dbg !19
  %556 = extractvalue { float, float, float, float } %553, 2, !dbg !19
  %557 = extractvalue { float, float, float, float } %553, 3, !dbg !19
  %558 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %519, float %520, float %521, float %522, i32 %313, i32 %314, i32 %315, i32 %316, i32 %404, i32 %406) #2, !dbg !19
  %559 = extractvalue { float, float, float, float } %558, 0, !dbg !19
  %560 = extractvalue { float, float, float, float } %558, 1, !dbg !19
  %561 = extractvalue { float, float, float, float } %558, 2, !dbg !19
  %562 = extractvalue { float, float, float, float } %558, 3, !dbg !19
  %563 = tail call { float, float, float, float } asm sideeffect "mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 { $0, $1, $2, $3 }, { $8, $9, $10, $11 }, { $12, $13 }, { $4, $5, $6, $7 };", "=f,=f,=f,=f,0,1,2,3,r,r,r,r,r,r"(float %524, float %525, float %526, float %527, i32 %313, i32 %314, i32 %315, i32 %316, i32 %405, i32 %407) #2, !dbg !19
  %564 = extractvalue { float, float, float, float } %563, 0, !dbg !19
  %565 = extractvalue { float, float, float, float } %563, 1, !dbg !19
  %566 = extractvalue { float, float, float, float } %563, 2, !dbg !19
  %567 = extractvalue { float, float, float, float } %563, 3, !dbg !19
  %568 = or disjoint i32 %38, %137, !dbg !20
  %569 = or disjoint i32 %38, %138, !dbg !20
  %570 = or disjoint i32 %38, %139, !dbg !20
  %571 = or disjoint i32 %38, %140, !dbg !20
  %572 = or disjoint i32 %568, 32, !dbg !20
  %573 = or disjoint i32 %568, 40, !dbg !20
  %574 = or disjoint i32 %568, 48, !dbg !20
  %575 = or disjoint i32 %568, 56, !dbg !20
  %576 = extractelement <2 x i32> %136, i64 0, !dbg !21
  %577 = or disjoint i32 %13, %576, !dbg !21
  %578 = or disjoint i32 %577, 1, !dbg !21
  %579 = or disjoint i32 %577, 2, !dbg !21
  %580 = or disjoint i32 %577, 3, !dbg !21
  %581 = mul i32 %568, %8, !dbg !22
  %582 = mul i32 %569, %8, !dbg !22
  %583 = mul i32 %570, %8, !dbg !22
  %584 = mul i32 %571, %8, !dbg !22
  %585 = mul i32 %572, %8, !dbg !22
  %586 = mul i32 %573, %8, !dbg !22
  %587 = mul i32 %574, %8, !dbg !22
  %588 = mul i32 %575, %8, !dbg !22
  %589 = sext i32 %581 to i64, !dbg !23
  %590 = getelementptr float, ptr addrspace(1) %2, i64 %589, !dbg !23
  %591 = sext i32 %582 to i64, !dbg !23
  %592 = getelementptr float, ptr addrspace(1) %2, i64 %591, !dbg !23
  %593 = sext i32 %583 to i64, !dbg !23
  %594 = getelementptr float, ptr addrspace(1) %2, i64 %593, !dbg !23
  %595 = sext i32 %584 to i64, !dbg !23
  %596 = getelementptr float, ptr addrspace(1) %2, i64 %595, !dbg !23
  %597 = sext i32 %585 to i64, !dbg !23
  %598 = getelementptr float, ptr addrspace(1) %2, i64 %597, !dbg !23
  %599 = sext i32 %586 to i64, !dbg !23
  %600 = getelementptr float, ptr addrspace(1) %2, i64 %599, !dbg !23
  %601 = sext i32 %587 to i64, !dbg !23
  %602 = getelementptr float, ptr addrspace(1) %2, i64 %601, !dbg !23
  %603 = sext i32 %588 to i64, !dbg !23
  %604 = getelementptr float, ptr addrspace(1) %2, i64 %603, !dbg !23
  %605 = sext i32 %577 to i64, !dbg !24
  %606 = getelementptr float, ptr addrspace(1) %590, i64 %605, !dbg !24
  %607 = sext i32 %578 to i64, !dbg !24
  %608 = getelementptr float, ptr addrspace(1) %590, i64 %607, !dbg !24
  %609 = sext i32 %579 to i64, !dbg !24
  %610 = getelementptr float, ptr addrspace(1) %590, i64 %609, !dbg !24
  %611 = sext i32 %580 to i64, !dbg !24
  %612 = getelementptr float, ptr addrspace(1) %590, i64 %611, !dbg !24
  %613 = getelementptr float, ptr addrspace(1) %592, i64 %605, !dbg !24
  %614 = getelementptr float, ptr addrspace(1) %592, i64 %607, !dbg !24
  %615 = getelementptr float, ptr addrspace(1) %592, i64 %609, !dbg !24
  %616 = getelementptr float, ptr addrspace(1) %592, i64 %611, !dbg !24
  %617 = getelementptr float, ptr addrspace(1) %594, i64 %605, !dbg !24
  %618 = getelementptr float, ptr addrspace(1) %594, i64 %607, !dbg !24
  %619 = getelementptr float, ptr addrspace(1) %594, i64 %609, !dbg !24
  %620 = getelementptr float, ptr addrspace(1) %594, i64 %611, !dbg !24
  %621 = getelementptr float, ptr addrspace(1) %596, i64 %605, !dbg !24
  %622 = getelementptr float, ptr addrspace(1) %596, i64 %607, !dbg !24
  %623 = getelementptr float, ptr addrspace(1) %596, i64 %609, !dbg !24
  %624 = getelementptr float, ptr addrspace(1) %596, i64 %611, !dbg !24
  %625 = getelementptr float, ptr addrspace(1) %598, i64 %605, !dbg !24
  %626 = getelementptr float, ptr addrspace(1) %598, i64 %607, !dbg !24
  %627 = getelementptr float, ptr addrspace(1) %598, i64 %609, !dbg !24
  %628 = getelementptr float, ptr addrspace(1) %598, i64 %611, !dbg !24
  %629 = getelementptr float, ptr addrspace(1) %600, i64 %605, !dbg !24
  %630 = getelementptr float, ptr addrspace(1) %600, i64 %607, !dbg !24
  %631 = getelementptr float, ptr addrspace(1) %600, i64 %609, !dbg !24
  %632 = getelementptr float, ptr addrspace(1) %600, i64 %611, !dbg !24
  %633 = getelementptr float, ptr addrspace(1) %602, i64 %605, !dbg !24
  %634 = getelementptr float, ptr addrspace(1) %602, i64 %607, !dbg !24
  %635 = getelementptr float, ptr addrspace(1) %602, i64 %609, !dbg !24
  %636 = getelementptr float, ptr addrspace(1) %602, i64 %611, !dbg !24
  %637 = getelementptr float, ptr addrspace(1) %604, i64 %605, !dbg !24
  %638 = getelementptr float, ptr addrspace(1) %604, i64 %607, !dbg !24
  %639 = getelementptr float, ptr addrspace(1) %604, i64 %609, !dbg !24
  %640 = getelementptr float, ptr addrspace(1) %604, i64 %611, !dbg !24
  %641 = icmp slt i32 %568, %3, !dbg !25
  %642 = icmp slt i32 %569, %3, !dbg !25
  %643 = icmp slt i32 %570, %3, !dbg !25
  %644 = icmp slt i32 %571, %3, !dbg !25
  %645 = icmp slt i32 %572, %3, !dbg !25
  %646 = icmp slt i32 %573, %3, !dbg !25
  %647 = icmp slt i32 %574, %3, !dbg !25
  %648 = icmp slt i32 %575, %3, !dbg !25
  %649 = icmp slt i32 %577, %4, !dbg !26
  %650 = and i1 %641, %649, !dbg !27
  %651 = and i1 %642, %649, !dbg !27
  %652 = and i1 %643, %649, !dbg !27
  %653 = and i1 %644, %649, !dbg !27
  %654 = and i1 %645, %649, !dbg !27
  %655 = and i1 %646, %649, !dbg !27
  %656 = and i1 %647, %649, !dbg !27
  %657 = and i1 %648, %649, !dbg !27
  tail call void @llvm.nvvm.barrier0(), !dbg !28
  %658 = shl nuw nsw i32 %319, 1, !dbg !28
  %659 = or disjoint i32 %318, %246, !dbg !28
  %660 = shl nuw nsw i32 %317, 3, !dbg !28
  %661 = or disjoint i32 %660, %658, !dbg !28
  %662 = mul nuw nsw i32 %659, 68, !dbg !28
  %663 = add nuw nsw i32 %662, %661, !dbg !28
  %664 = zext nneg i32 %663 to i64, !dbg !28
  %665 = getelementptr float, ptr addrspace(3) @global_smem, i64 %664, !dbg !28
  %666 = insertelement <2 x float> poison, float %529, i64 0, !dbg !28
  %667 = insertelement <2 x float> %666, float %530, i64 1, !dbg !28
  store <2 x float> %667, ptr addrspace(3) %665, align 8, !dbg !28
  %668 = add nuw nsw i32 %662, 544, !dbg !28
  %669 = add nuw nsw i32 %668, %661, !dbg !28
  %670 = zext nneg i32 %669 to i64, !dbg !28
  %671 = getelementptr float, ptr addrspace(3) @global_smem, i64 %670, !dbg !28
  %672 = insertelement <2 x float> poison, float %531, i64 0, !dbg !28
  %673 = insertelement <2 x float> %672, float %532, i64 1, !dbg !28
  store <2 x float> %673, ptr addrspace(3) %671, align 8, !dbg !28
  %674 = or disjoint i32 %661, 16, !dbg !28
  %675 = add nuw nsw i32 %674, %662, !dbg !28
  %676 = zext nneg i32 %675 to i64, !dbg !28
  %677 = getelementptr float, ptr addrspace(3) @global_smem, i64 %676, !dbg !28
  %678 = insertelement <2 x float> poison, float %534, i64 0, !dbg !28
  %679 = insertelement <2 x float> %678, float %535, i64 1, !dbg !28
  store <2 x float> %679, ptr addrspace(3) %677, align 8, !dbg !28
  %680 = add nuw nsw i32 %668, %674, !dbg !28
  %681 = zext nneg i32 %680 to i64, !dbg !28
  %682 = getelementptr float, ptr addrspace(3) @global_smem, i64 %681, !dbg !28
  %683 = insertelement <2 x float> poison, float %536, i64 0, !dbg !28
  %684 = insertelement <2 x float> %683, float %537, i64 1, !dbg !28
  store <2 x float> %684, ptr addrspace(3) %682, align 8, !dbg !28
  %685 = or disjoint i32 %661, 32, !dbg !28
  %686 = add nuw nsw i32 %685, %662, !dbg !28
  %687 = zext nneg i32 %686 to i64, !dbg !28
  %688 = getelementptr float, ptr addrspace(3) @global_smem, i64 %687, !dbg !28
  %689 = insertelement <2 x float> poison, float %539, i64 0, !dbg !28
  %690 = insertelement <2 x float> %689, float %540, i64 1, !dbg !28
  store <2 x float> %690, ptr addrspace(3) %688, align 8, !dbg !28
  %691 = add nuw nsw i32 %668, %685, !dbg !28
  %692 = zext nneg i32 %691 to i64, !dbg !28
  %693 = getelementptr float, ptr addrspace(3) @global_smem, i64 %692, !dbg !28
  %694 = insertelement <2 x float> poison, float %541, i64 0, !dbg !28
  %695 = insertelement <2 x float> %694, float %542, i64 1, !dbg !28
  store <2 x float> %695, ptr addrspace(3) %693, align 8, !dbg !28
  %696 = or disjoint i32 %661, 48, !dbg !28
  %697 = add nuw nsw i32 %696, %662, !dbg !28
  %698 = zext nneg i32 %697 to i64, !dbg !28
  %699 = getelementptr float, ptr addrspace(3) @global_smem, i64 %698, !dbg !28
  %700 = insertelement <2 x float> poison, float %544, i64 0, !dbg !28
  %701 = insertelement <2 x float> %700, float %545, i64 1, !dbg !28
  store <2 x float> %701, ptr addrspace(3) %699, align 8, !dbg !28
  %702 = add nuw nsw i32 %668, %696, !dbg !28
  %703 = zext nneg i32 %702 to i64, !dbg !28
  %704 = getelementptr float, ptr addrspace(3) @global_smem, i64 %703, !dbg !28
  %705 = insertelement <2 x float> poison, float %546, i64 0, !dbg !28
  %706 = insertelement <2 x float> %705, float %547, i64 1, !dbg !28
  store <2 x float> %706, ptr addrspace(3) %704, align 8, !dbg !28
  tail call void @llvm.nvvm.barrier0(), !dbg !28
  %707 = shl nuw nsw i32 %20, 1, !dbg !28
  %708 = and i32 %707, 6, !dbg !28
  %709 = or disjoint i32 %708, %244, !dbg !28
  %710 = and i32 %23, 60, !dbg !28
  %711 = mul nuw nsw i32 %709, 68, !dbg !28
  %712 = add nuw nsw i32 %711, %710, !dbg !28
  %713 = zext nneg i32 %712 to i64, !dbg !28
  %714 = getelementptr float, ptr addrspace(3) @global_smem, i64 %713, !dbg !28
  %715 = load <4 x float>, ptr addrspace(3) %714, align 16, !dbg !28
  %716 = getelementptr i8, ptr addrspace(3) %714, i64 2176, !dbg !28
  %717 = load <4 x float>, ptr addrspace(3) %716, align 16, !dbg !28
  %718 = getelementptr i8, ptr addrspace(3) %714, i64 4352, !dbg !28
  %719 = load <4 x float>, ptr addrspace(3) %718, align 16, !dbg !28
  %720 = getelementptr i8, ptr addrspace(3) %714, i64 6528, !dbg !28
  %721 = load <4 x float>, ptr addrspace(3) %720, align 16, !dbg !28
  tail call void @llvm.nvvm.barrier0(), !dbg !28
  %722 = insertelement <2 x float> poison, float %549, i64 0, !dbg !28
  %723 = insertelement <2 x float> %722, float %550, i64 1, !dbg !28
  store <2 x float> %723, ptr addrspace(3) %665, align 8, !dbg !28
  %724 = insertelement <2 x float> poison, float %551, i64 0, !dbg !28
  %725 = insertelement <2 x float> %724, float %552, i64 1, !dbg !28
  store <2 x float> %725, ptr addrspace(3) %671, align 8, !dbg !28
  %726 = insertelement <2 x float> poison, float %554, i64 0, !dbg !28
  %727 = insertelement <2 x float> %726, float %555, i64 1, !dbg !28
  store <2 x float> %727, ptr addrspace(3) %677, align 8, !dbg !28
  %728 = insertelement <2 x float> poison, float %556, i64 0, !dbg !28
  %729 = insertelement <2 x float> %728, float %557, i64 1, !dbg !28
  store <2 x float> %729, ptr addrspace(3) %682, align 8, !dbg !28
  %730 = insertelement <2 x float> poison, float %559, i64 0, !dbg !28
  %731 = insertelement <2 x float> %730, float %560, i64 1, !dbg !28
  store <2 x float> %731, ptr addrspace(3) %688, align 8, !dbg !28
  %732 = insertelement <2 x float> poison, float %561, i64 0, !dbg !28
  %733 = insertelement <2 x float> %732, float %562, i64 1, !dbg !28
  store <2 x float> %733, ptr addrspace(3) %693, align 8, !dbg !28
  %734 = insertelement <2 x float> poison, float %564, i64 0, !dbg !28
  %735 = insertelement <2 x float> %734, float %565, i64 1, !dbg !28
  store <2 x float> %735, ptr addrspace(3) %699, align 8, !dbg !28
  %736 = insertelement <2 x float> poison, float %566, i64 0, !dbg !28
  %737 = insertelement <2 x float> %736, float %567, i64 1, !dbg !28
  store <2 x float> %737, ptr addrspace(3) %704, align 8, !dbg !28
  tail call void @llvm.nvvm.barrier0(), !dbg !28
  %738 = load <4 x float>, ptr addrspace(3) %714, align 16, !dbg !28
  %739 = load <4 x float>, ptr addrspace(3) %716, align 16, !dbg !28
  %740 = load <4 x float>, ptr addrspace(3) %718, align 16, !dbg !28
  %741 = load <4 x float>, ptr addrspace(3) %720, align 16, !dbg !28
  %742 = shufflevector <4 x float> %715, <4 x float> poison, <1 x i32> zeroinitializer, !dbg !28
  %743 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %606, <1 x float> %742, i1 %650) #2, !dbg !28
  %744 = shufflevector <4 x float> %715, <4 x float> poison, <1 x i32> <i32 1>, !dbg !28
  %745 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %608, <1 x float> %744, i1 %650) #2, !dbg !28
  %746 = shufflevector <4 x float> %715, <4 x float> poison, <1 x i32> <i32 2>, !dbg !28
  %747 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %610, <1 x float> %746, i1 %650) #2, !dbg !28
  %748 = shufflevector <4 x float> %715, <4 x float> poison, <1 x i32> <i32 3>, !dbg !28
  %749 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %612, <1 x float> %748, i1 %650) #2, !dbg !28
  %750 = shufflevector <4 x float> %717, <4 x float> poison, <1 x i32> zeroinitializer, !dbg !28
  %751 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %613, <1 x float> %750, i1 %651) #2, !dbg !28
  %752 = shufflevector <4 x float> %717, <4 x float> poison, <1 x i32> <i32 1>, !dbg !28
  %753 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %614, <1 x float> %752, i1 %651) #2, !dbg !28
  %754 = shufflevector <4 x float> %717, <4 x float> poison, <1 x i32> <i32 2>, !dbg !28
  %755 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %615, <1 x float> %754, i1 %651) #2, !dbg !28
  %756 = shufflevector <4 x float> %717, <4 x float> poison, <1 x i32> <i32 3>, !dbg !28
  %757 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %616, <1 x float> %756, i1 %651) #2, !dbg !28
  %758 = shufflevector <4 x float> %719, <4 x float> poison, <1 x i32> zeroinitializer, !dbg !28
  %759 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %617, <1 x float> %758, i1 %652) #2, !dbg !28
  %760 = shufflevector <4 x float> %719, <4 x float> poison, <1 x i32> <i32 1>, !dbg !28
  %761 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %618, <1 x float> %760, i1 %652) #2, !dbg !28
  %762 = shufflevector <4 x float> %719, <4 x float> poison, <1 x i32> <i32 2>, !dbg !28
  %763 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %619, <1 x float> %762, i1 %652) #2, !dbg !28
  %764 = shufflevector <4 x float> %719, <4 x float> poison, <1 x i32> <i32 3>, !dbg !28
  %765 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %620, <1 x float> %764, i1 %652) #2, !dbg !28
  %766 = shufflevector <4 x float> %721, <4 x float> poison, <1 x i32> zeroinitializer, !dbg !28
  %767 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %621, <1 x float> %766, i1 %653) #2, !dbg !28
  %768 = shufflevector <4 x float> %721, <4 x float> poison, <1 x i32> <i32 1>, !dbg !28
  %769 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %622, <1 x float> %768, i1 %653) #2, !dbg !28
  %770 = shufflevector <4 x float> %721, <4 x float> poison, <1 x i32> <i32 2>, !dbg !28
  %771 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %623, <1 x float> %770, i1 %653) #2, !dbg !28
  %772 = shufflevector <4 x float> %721, <4 x float> poison, <1 x i32> <i32 3>, !dbg !28
  %773 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %624, <1 x float> %772, i1 %653) #2, !dbg !28
  %774 = shufflevector <4 x float> %738, <4 x float> poison, <1 x i32> zeroinitializer, !dbg !28
  %775 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %625, <1 x float> %774, i1 %654) #2, !dbg !28
  %776 = shufflevector <4 x float> %738, <4 x float> poison, <1 x i32> <i32 1>, !dbg !28
  %777 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %626, <1 x float> %776, i1 %654) #2, !dbg !28
  %778 = shufflevector <4 x float> %738, <4 x float> poison, <1 x i32> <i32 2>, !dbg !28
  %779 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %627, <1 x float> %778, i1 %654) #2, !dbg !28
  %780 = shufflevector <4 x float> %738, <4 x float> poison, <1 x i32> <i32 3>, !dbg !28
  %781 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %628, <1 x float> %780, i1 %654) #2, !dbg !28
  %782 = shufflevector <4 x float> %739, <4 x float> poison, <1 x i32> zeroinitializer, !dbg !28
  %783 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %629, <1 x float> %782, i1 %655) #2, !dbg !28
  %784 = shufflevector <4 x float> %739, <4 x float> poison, <1 x i32> <i32 1>, !dbg !28
  %785 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %630, <1 x float> %784, i1 %655) #2, !dbg !28
  %786 = shufflevector <4 x float> %739, <4 x float> poison, <1 x i32> <i32 2>, !dbg !28
  %787 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %631, <1 x float> %786, i1 %655) #2, !dbg !28
  %788 = shufflevector <4 x float> %739, <4 x float> poison, <1 x i32> <i32 3>, !dbg !28
  %789 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %632, <1 x float> %788, i1 %655) #2, !dbg !28
  %790 = shufflevector <4 x float> %740, <4 x float> poison, <1 x i32> zeroinitializer, !dbg !28
  %791 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %633, <1 x float> %790, i1 %656) #2, !dbg !28
  %792 = shufflevector <4 x float> %740, <4 x float> poison, <1 x i32> <i32 1>, !dbg !28
  %793 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %634, <1 x float> %792, i1 %656) #2, !dbg !28
  %794 = shufflevector <4 x float> %740, <4 x float> poison, <1 x i32> <i32 2>, !dbg !28
  %795 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %635, <1 x float> %794, i1 %656) #2, !dbg !28
  %796 = shufflevector <4 x float> %740, <4 x float> poison, <1 x i32> <i32 3>, !dbg !28
  %797 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %636, <1 x float> %796, i1 %656) #2, !dbg !28
  %798 = shufflevector <4 x float> %741, <4 x float> poison, <1 x i32> zeroinitializer, !dbg !28
  %799 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %637, <1 x float> %798, i1 %657) #2, !dbg !28
  %800 = shufflevector <4 x float> %741, <4 x float> poison, <1 x i32> <i32 1>, !dbg !28
  %801 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %638, <1 x float> %800, i1 %657) #2, !dbg !28
  %802 = shufflevector <4 x float> %741, <4 x float> poison, <1 x i32> <i32 2>, !dbg !28
  %803 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %639, <1 x float> %802, i1 %657) #2, !dbg !28
  %804 = shufflevector <4 x float> %741, <4 x float> poison, <1 x i32> <i32 3>, !dbg !28
  %805 = tail call float asm sideeffect "mov.u32 $0, 0x0;\0A\09@$3 atom.global.gpu.acq_rel.add.f32 $0, [ $1 + 0 ], $2;", "=r,l,r,b"(ptr addrspace(1) %640, <1 x float> %804, i1 %657) #2, !dbg !28
  ret void, !dbg !29
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.nvvm.read.ptx.sreg.tid.x() #0

; Function Attrs: convergent nocallback nounwind
declare void @llvm.nvvm.barrier0() #1

attributes #0 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #1 = { convergent nocallback nounwind }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1}
!llvm.dbg.cu = !{!2}
!nvvm.annotations = !{!4, !5}
!llvm.ident = !{!6}

!0 = !{i32 2, !"Debug Info Version", i32 3}
!1 = !{i32 4, !"nvvm-reflect-ftz", i32 1}
!2 = distinct !DICompileUnit(language: DW_LANG_C, file: !3, producer: "triton", isOptimized: true, runtimeVersion: 0, emissionKind: LineTablesOnly)
!3 = !DIFile(filename: "main.py", directory: "/data/sunyunbo/workspace/src/ai_practice/triton")
!4 = !{ptr @matmul_split_k_kernel, !"kernel", i32 1}
!5 = !{ptr @matmul_split_k_kernel, !"maxntidx", i32 128}
!6 = !{!"clang version 3.8.0 (tags/RELEASE_380/final)"}
!7 = distinct !DISubprogram(name: "matmul_split_k_kernel", linkageName: "matmul_split_k_kernel", scope: !3, file: !3, line: 7, type: !8, scopeLine: 7, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !2)
!8 = !DISubroutineType(cc: DW_CC_normal, types: !9)
!9 = !{}
!10 = !DILocation(line: 25, column: 26, scope: !7)
!11 = !DILocation(line: 26, column: 26, scope: !7)
!12 = !DILocation(line: 27, column: 26, scope: !7)
!13 = !DILocation(line: 32, column: 20, scope: !7)
!14 = !DILocation(line: 41, column: 8, scope: !7)
!15 = !DILocation(line: 49, column: 8, scope: !7)
!16 = !DILocation(line: 53, column: 16, scope: !7)
!17 = !DILocation(line: 31, column: 20, scope: !7)
!18 = !DILocation(line: 54, column: 16, scope: !7)
!19 = !DILocation(line: 57, column: 20, scope: !7)
!20 = !DILocation(line: 60, column: 21, scope: !7)
!21 = !DILocation(line: 61, column: 21, scope: !7)
!22 = !DILocation(line: 62, column: 39, scope: !7)
!23 = !DILocation(line: 62, column: 21, scope: !7)
!24 = !DILocation(line: 62, column: 51, scope: !7)
!25 = !DILocation(line: 63, column: 30, scope: !7)
!26 = !DILocation(line: 63, column: 54, scope: !7)
!27 = !DILocation(line: 63, column: 36, scope: !7)
!28 = !DILocation(line: 66, column: 26, scope: !7)
!29 = !DILocation(line: 66, column: 4, scope: !7)
