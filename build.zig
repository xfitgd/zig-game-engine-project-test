const std = @import("std");
const builtin = @import("builtin");

//* User Setting
//크로스 플랫폼 빌드시 zig build -Dtarget=aarch64-windows(linux)
//x86_64-windows(linux)
//? Android 쪽은 한번 테스트하고 안해서(Windows쪽 완성되면 할 예정) 버그 있을 겁니다.

const PLATFORM = XfitPlatform.windows;
const ANDROID_PATH = "C:/Android";
const ANDROID_NDK_PATH = std.fmt.comptimePrint("{s}/ndk/27.0.11718014", .{ANDROID_PATH});
const ANDROID_VER = 34;
const VULKAN_INC_PATH = "C:/vk/include";

//keystore 없으면 생성
//keytool -genkey -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000
const ANDROID_KEYSTORE = "debug.keystore";

const OPTIMIZE = std.builtin.OptimizeMode.Debug;

//*

pub const XfitPlatform = enum(u32) { windows, android, linux, mac, end };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const platform = b.option(XfitPlatform, "platform", "build platform") orelse PLATFORM;

    const build_options = b.addOptions();

    build_options.addOption(XfitPlatform, "platform", platform);

    const arch_text = comptime [_][]const u8{
        "aarch64-linux-android",
        //"arm-linux-androideabi", not support vulkan
        //"i686-linux-android",
        "x86_64-linux-android",
    };
    const out_arch_text = comptime [_][]const u8{
        "../lib/arm64-v8a",
        //"armeabi-v7a",
        //"x86",
        "../lib/x86_64",
    };
    const targets = [_]std.zig.CrossTarget{
        .{ .os_tag = .linux, .cpu_arch = .aarch64, .abi = .android, .cpu_features_add = std.Target.aarch64.featureSet(&.{.v8a}) },
        //.{ .os_tag = .linux, .cpu_arch = .arm, .abi = .android, .cpu_features_add = std.Target.arm.featureSet(&.{.v7a}) },
        //.{ .os_tag = .linux, .cpu_arch = .x86, .abi = .android },
        .{ .os_tag = .linux, .cpu_arch = .x86_64, .abi = .android },
    };

    var install_step: *std.Build.Step = undefined;
    if (platform == XfitPlatform.android) {
        install_step = b.step("shared lib build", "shared lib build");
    } else {
        install_step = b.default_step;
    }

    comptime var i = 0;
    inline while (i < targets.len) : (i += 1) {
        var solib: *std.Build.Step.Compile = undefined;
        var exe: *std.Build.Step.Compile = undefined;

        const __vulkan = b.addModule("__vulkan", .{ .root_source_file = b.path("zig-game-engine-project/__vulkan.zig") });

        const build_options_module = build_options.createModule();

        if (platform == XfitPlatform.android) {
            solib = b.addSharedLibrary(.{
                .target = b.resolveTargetQuery(targets[i]),
                .name = "XfitTest",
                .root_source_file = b.path("main.zig"),
                .optimize = OPTIMIZE,
                .pic = true,
            });
            //if (i == 2) solib.link_z_notext = true; //x86 only

            var contents = std.ArrayList(u8).init(b.allocator);
            errdefer contents.deinit();

            var writer = contents.writer();
            //  The directory that contains `stdlib.h`.
            //  On POSIX-like systems, include directories be found with: `cc -E -Wp,-v -xc /dev/null
            writer.print("include_dir={s}\n", .{comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include", .{ANDROID_NDK_PATH})}) catch unreachable;

            //writer.print("sys_include_dir={s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include/c++/v1\n", .{ANDROID_NDK_PATH}) catch unreachable;

            // The system-specific include directory. May be the same as `include_dir`.
            // On Windows it's the directory that includes `vcruntime.h`.
            // On POSIX it's the directory that includes `sys/errno.h`.
            writer.print("sys_include_dir={s}\n", .{comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include/{s}", .{ ANDROID_NDK_PATH, arch_text[i] })}) catch unreachable;

            writer.print("crt_dir={s}\n", .{comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/{s}/{d}", .{ ANDROID_NDK_PATH, arch_text[i], ANDROID_VER })}) catch unreachable;

            writer.writeAll("msvc_lib_dir=\n") catch unreachable;
            writer.writeAll("kernel32_lib_dir=\n") catch unreachable;
            writer.writeAll("gcc_dir=\n") catch unreachable;

            const step = b.addWriteFile("android-libc.conf", contents.items);

            solib.setLibCFile(step.files.items[0].getPath());

            install_step.dependOn(&step.step);
            //solib.subsystem = .Posix;

            // ?? c++
            //solib.addIncludePath(.{ .cwd_relative = comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include/c++/v1", .{ANDROID_NDK_PATH})});

            solib.addSystemIncludePath(.{ .cwd_relative = comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include/{s}", .{ ANDROID_NDK_PATH, arch_text[i] }) });

            solib.addSystemIncludePath(.{ .cwd_relative = comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/lib/clang/18/include", .{ANDROID_NDK_PATH}) });

            solib.addSystemIncludePath(.{ .cwd_relative = comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include", .{ANDROID_NDK_PATH}) });
            solib.addSystemIncludePath(b.path("."));

            __vulkan.addSystemIncludePath(.{ .cwd_relative = comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include/{s}", .{ ANDROID_NDK_PATH, arch_text[i] }) });

            //?? unused
            // solib.addCSourceFile(.{.file = b.path("android_glue.c"), .flags = &[_][]const u8{"-fPIC",
            // comptime std.fmt.comptimePrint("-I{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include",.{ANDROID_NDK_PATH}),
            // comptime std.fmt.comptimePrint("-I{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include/c++/v1",.{ANDROID_NDK_PATH}),
            // comptime std.fmt.comptimePrint("-I{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/include/{s}",.{ANDROID_NDK_PATH, arch_text[i]})}});

            // !! ERROR CODE
            // solib.addLibraryPath(.{ .cwd_relative = comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/{s}", .{ANDROID_NDK_PATH, arch_text[i]})});
            // !!

            solib.addLibraryPath(.{ .cwd_relative = comptime std.fmt.comptimePrint("{s}/toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib/{s}/{d}", .{ ANDROID_NDK_PATH, arch_text[i], ANDROID_VER }) });

            // solib.linkSystemLibrary("c++_static");
            // solib.linkSystemLibrary("c++abi");
            solib.linkSystemLibrary("android");
            solib.linkSystemLibrary("vulkan");
            solib.linkSystemLibrary("c");
            solib.linkSystemLibrary("log");

            solib.root_module.addImport("build_options", build_options_module);

            install_step.dependOn(&b.addInstallArtifact(solib, .{
                .dest_dir = .{ .override = .{ .custom = out_arch_text[i] } },
            }).step);
        } else if (platform == XfitPlatform.windows) {
            exe = b.addExecutable(.{
                .target = target,
                .name = "XfitTest",
                .root_source_file = b.path("main.zig"),
                .optimize = OPTIMIZE,
            });
            exe.linkLibC();

            __vulkan.addIncludePath(.{ .cwd_relative = VULKAN_INC_PATH });
            exe.addIncludePath(.{ .cwd_relative = VULKAN_INC_PATH });

            exe.addObjectFile(b.path("zig-game-engine-project/lib/vulkan.lib"));
            exe.subsystem = .Windows;

            exe.root_module.addImport("build_options", build_options_module);
            b.installArtifact(exe);
        } else unreachable;
        if (platform != XfitPlatform.android) break;
    }

    if (platform == XfitPlatform.android) {
        //aapt2 compile --dir res -o res.zip
        const cmd = b.addSystemCommand(&.{ "aapt2", "compile", "--dir", "res", "-o", "zig-out/res.zip" });

        //aapt2 link -o zig-out/output.apk -I C:/Android/platforms/android-34/android.jar zig-out/res.zip --java . --manifest AndroidManifest.xml
        const cmd2 = b.addSystemCommand(&.{ "aapt2", "link", "-o", "zig-out/output.apk", "-I", comptime std.fmt.comptimePrint("{s}/platforms/android-{d}/android.jar", .{ ANDROID_PATH, ANDROID_VER }), "zig-out/res.zip", "--java", ".", "--manifest", "AndroidManifest.xml" });

        //zip -r zig-out/output.apk ../lib/
        const cmd3 = b.addSystemCommand(&.{ "zip", "-r", "zig-out/output.apk", "lib/" });

        //zip -r zig-out/output.apk ../assets/
        const cmd4 = b.addSystemCommand(&.{ "zip", "-r", "zig-out/output.apk", "assets/" });

        //zipalign -p -f -v 4 zig-out/output.apk zig-out/unsigned.apk
        const cmd5 = b.addSystemCommand(&.{ "zipalign", "-p", "-f", "-v", "4", "zig-out/output.apk", "zig-out/unsigned.apk" });

        //apksigner sign --ks debug.keystore --ks-pass pass:android --out zig-out/signed.apk zig-out/unsigned.apk
        const cmd6 = b.addSystemCommand(&.{ "apksigner", "sign", "--ks", ANDROID_KEYSTORE, "--ks-pass", "pass:android", "--out", "zig-out/signed.apk", "zig-out/unsigned.apk" });

        cmd6.step.dependOn(&cmd5.step);
        cmd5.step.dependOn(&cmd4.step);
        cmd4.step.dependOn(&cmd3.step);
        cmd3.step.dependOn(&cmd2.step);
        cmd2.step.dependOn(&cmd.step);
        cmd.step.dependOn(install_step);

        b.default_step.dependOn(&cmd6.step);
    }
}
