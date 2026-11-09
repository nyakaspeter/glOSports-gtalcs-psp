# Third-party components

The port builds on and ships with:

| Component | Licence | Text |
|---|---|---|
| [lcs-recomp](https://github.com/elmasas/lcs-recomp) at `1132a76`: the recompiler, runtime and host code `LCSNative` is built from | MIT | `psprecomp.LICENSE.txt` |
| ARM's Mali user-space driver (`glos/lib/libMali.so`) | ARM proprietary | `libMali.txt` |
| ARM's Mali kernel driver (`glos/mali.ko`) | GPL-2.0 | goodluckOS-mali-driver |

`LCSNative` also holds code recompiled from the game's own executable, which is Rockstar's and
not covered by any licence here.

The libraries in `lib/` are Debian bookworm's armhf packages, unchanged (stripped). Each package's
Debian copyright file is here as `<package>.copyright.txt`; the licence column is the main one it
declares (the files list every licence that applies, and refer to Debian's
`/usr/share/common-licenses/` for the full GPL/LGPL texts).

| Debian package | Libraries | Licence | Text |
|---|---|---|---|
| `libaom3` 3.6.0-1+deb12u3 | `libaom.so.3` | BSD-2-clause | `libaom3.copyright.txt` |
| `libavcodec59` 7:5.1.9-0+deb12u1 | `libavcodec.so.59` | LGPL-2.1+ | `libavcodec59.copyright.txt` |
| `libavformat59` 7:5.1.9-0+deb12u1 | `libavformat.so.59` | LGPL-2.1+ | `libavformat59.copyright.txt` |
| `libavutil57` 7:5.1.9-0+deb12u1 | `libavutil.so.57` | LGPL-2.1+ | `libavutil57.copyright.txt` |
| `libbluray2` 1:1.3.4-1 | `libbluray.so.2` | LGPL-2.1+ | `libbluray2.copyright.txt` |
| `libbsd0` 0.11.7-2 | `libbsd.so.0` | BSD-3-clause | `libbsd0.copyright.txt` |
| `libbz2-1.0` 1.0.8-5+b1 | `libbz2.so.1.0` | BSD-variant | `libbz2-1.0.copyright.txt` |
| `libcairo-gobject2` 1.16.0-7 | `libcairo-gobject.so.2` | see the file | `libcairo-gobject2.copyright.txt` |
| `libcairo2` 1.16.0-7 | `libcairo.so.2` | see the file | `libcairo2.copyright.txt` |
| `libchromaprint1` 1.5.1-2+b1 | `libchromaprint.so.1` | Expat | `libchromaprint1.copyright.txt` |
| `libcjson1` 1.7.15-1+deb12u4 | `libcjson.so.1` | MIT | `libcjson1.copyright.txt` |
| `libcodec2-1.0` 1.0.5-1 | `libcodec2.so.1.0` | LGPL-2.1 | `libcodec2-1.0.copyright.txt` |
| `libcom-err2` 1.47.0-2+b2 | `libcom_err.so.2` | GPL-2 | `libcom-err2.copyright.txt` |
| `libdatrie1` 0.2.13-2+b1 | `libdatrie.so.1` | LGPL-2.1+ | `libdatrie1.copyright.txt` |
| `libdav1d6` 1.0.0-2+deb12u1 | `libdav1d.so.6` | BSD-2-clause | `libdav1d6.copyright.txt` |
| `libfontconfig1` 2.14.1-4 | `libfontconfig.so.1` | see the file | `libfontconfig1.copyright.txt` |
| `libfribidi0` 1.0.8-2.1 | `libfribidi.so.0` | LGPL-2.1+ | `libfribidi0.copyright.txt` |
| `libgdk-pixbuf-2.0-0` 2.42.10+dfsg-1+deb12u4 | `libgdk_pixbuf-2.0.so.0` | LGPL-2+ and LGPL-2.1+ and CC0-1.0 | `libgdk-pixbuf-2.0-0.copyright.txt` |
| `libgme0` 0.6.3-6 | `libgme.so.0` | LGPL-2.1+ | `libgme0.copyright.txt` |
| `libgmp10` 2:6.2.1+dfsg1-1.1 | `libgmp.so.10` | GPL-2+ or LGPL-3+ | `libgmp10.copyright.txt` |
| `libgnutls30` 3.7.9-2+deb12u7 | `libgnutls.so.30` | see the file | `libgnutls30.copyright.txt` |
| `libgraphite2-3` 1.3.14-1+deb12u1 | `libgraphite2.so.3` | LGPL-2.1+ or MPL-1.1 or GPL-2+ | `libgraphite2-3.copyright.txt` |
| `libgsm1` 1.0.22-1 | `libgsm.so.1` | TU-Berlin-2.0 | `libgsm1.copyright.txt` |
| `libgssapi-krb5-2` 1.20.1-2+deb12u5 | `libgssapi_krb5.so.2` | see the file | `libgssapi-krb5-2.copyright.txt` |
| `libharfbuzz0b` 6.0.0+dfsg-3 | `libharfbuzz.so.0` | MIT | `libharfbuzz0b.copyright.txt` |
| `libhogweed6` 3.8.1-2 | `libhogweed.so.6` | LGPL-3+ or GPL-2+ | `libhogweed6.copyright.txt` |
| `libhwy1` 1.0.3-3+deb12u1 | `libhwy.so.1` | Apache-2.0 | `libhwy1.copyright.txt` |
| `libicu72` 72.1-3+deb12u1 | `libicudata.so.72`, `libicuuc.so.72` | MIT | `libicu72.copyright.txt` |
| `libidn2-0` 2.3.3-1+b1 | `libidn2.so.0` | GPL-3+ | `libidn2-0.copyright.txt` |
| `libjpeg62-turbo` 1:2.1.5-2 | `libjpeg.so.62` | BSD-BY-LC-NE | `libjpeg62-turbo.copyright.txt` |
| `libjxl0.7` 0.7.0-10+deb12u1 | `libjxl.so.0.7`, `libjxl_threads.so.0.7` | BSD-3-clause-Google | `libjxl0.7.copyright.txt` |
| `libk5crypto3` 1.20.1-2+deb12u5 | `libk5crypto.so.3` | see the file | `libk5crypto3.copyright.txt` |
| `libkeyutils1` 1.6.3-2 | `libkeyutils.so.1` | GPL-2+ | `libkeyutils1.copyright.txt` |
| `libkrb5-3` 1.20.1-2+deb12u5 | `libkrb5.so.3` | see the file | `libkrb5-3.copyright.txt` |
| `libkrb5support0` 1.20.1-2+deb12u5 | `libkrb5support.so.0` | see the file | `libkrb5support0.copyright.txt` |
| `liblcms2-2` 2.14-2+deb12u1 | `liblcms2.so.2` | MIT | `liblcms2-2.copyright.txt` |
| `liblzma5` 5.4.1-1+deb12u2 | `liblzma.so.5` | PD | `liblzma5.copyright.txt` |
| `libmbedcrypto7` 2.28.3-1 | `libmbedcrypto.so.7` | Apache-2.0 | `libmbedcrypto7.copyright.txt` |
| `libmd0` 1.0.4-2 | `libmd.so.0` | BSD-3-clause | `libmd0.copyright.txt` |
| `libmp3lame0` 3.100-6 | `libmp3lame.so.0` | LGPL-2+ | `libmp3lame0.copyright.txt` |
| `libmpg123-0` 1.31.2-1+deb12u1 | `libmpg123.so.0` | LGPL-2.1 | `libmpg123-0.copyright.txt` |
| `libnettle8` 3.8.1-2 | `libnettle.so.8` | LGPL-3+ or GPL-2+ | `libnettle8.copyright.txt` |
| `libnorm1` 1.5.9+dfsg-2 | `libnorm.so.1` | NRL-2-clause | `libnorm1.copyright.txt` |
| `libogg0` 1.3.5-3 | `libogg.so.0` | BSD-3-clause | `libogg0.copyright.txt` |
| `libopenjp2-7` 2.5.0-2+deb12u3 | `libopenjp2.so.7` | BSD-2 | `libopenjp2-7.copyright.txt` |
| `libopenmpt0` 0.6.9-1 | `libopenmpt.so.0` | BSD-3-clause | `libopenmpt0.copyright.txt` |
| `libopus0` 1.3.1-3 | `libopus.so.0` | BSD-3-clause | `libopus0.copyright.txt` |
| `libp11-kit0` 0.24.1-2 | `libp11-kit.so.0` | BSD-3-Clause | `libp11-kit0.copyright.txt` |
| `libpango-1.0-0` 1.50.12+ds-1 | `libpango-1.0.so.0` | LGPL-2+ and LGPL-2.1+ | `libpango-1.0-0.copyright.txt` |
| `libpangocairo-1.0-0` 1.50.12+ds-1 | `libpangocairo-1.0.so.0` | LGPL-2+ and LGPL-2.1+ | `libpangocairo-1.0-0.copyright.txt` |
| `libpangoft2-1.0-0` 1.50.12+ds-1 | `libpangoft2-1.0.so.0` | LGPL-2+ and LGPL-2.1+ | `libpangoft2-1.0-0.copyright.txt` |
| `libpgm-5.3-0` 5.3.128~dfsg-2 | `libpgm-5.3.so.0` | LGPL-2.1 | `libpgm-5.3-0.copyright.txt` |
| `libpixman-1-0` 0.42.2-1 | `libpixman-1.so.0` | see the file | `libpixman-1-0.copyright.txt` |
| `librabbitmq4` 0.11.0-1+deb12u3 | `librabbitmq.so.4` | Expat | `librabbitmq4.copyright.txt` |
| `librav1e0` 0.5.1-6 | `librav1e.so.0` | BSD-2-clause | `librav1e0.copyright.txt` |
| `librist4` 0.2.7+dfsg-1 | `librist.so.4` | BSD-2-clause | `librist4.copyright.txt` |
| `librsvg2-2` 2.54.7+dfsg-1~deb12u1 | `librsvg-2.so.2` | LGPL-2+ | `librsvg2-2.copyright.txt` |
| `libshine3` 3.1.1-2 | `libshine.so.3` | LGPL-2 | `libshine3.copyright.txt` |
| `libsnappy1v5` 1.1.9-3 | `libsnappy.so.1` | BSD-3-Clause | `libsnappy1v5.copyright.txt` |
| `libsodium23` 1.0.18-1+deb12u1 | `libsodium.so.23` | ISC | `libsodium23.copyright.txt` |
| `libsoxr0` 0.1.3-4 | `libsoxr.so.0` | LGPL-2.1+ | `libsoxr0.copyright.txt` |
| `libspeex1` 1.2.1-2 | `libspeex.so.1` | BSD-3-Clause | `libspeex1.copyright.txt` |
| `libsrt1.5-gnutls` 1.5.1-1+deb12u1 | `libsrt-gnutls.so.1.5` | MPL-2.0 | `libsrt1.5-gnutls.copyright.txt` |
| `libssh-gcrypt-4` 0.10.6-0+deb12u3 | `libssh-gcrypt.so.4` | LGPL-2.1+~OpenSSL | `libssh-gcrypt-4.copyright.txt` |
| `libssl3` 3.0.22-1~deb12u2 | `libcrypto.so.3`, `libssl.so.3` | Apache-2.0 | `libssl3.copyright.txt` |
| `libsvtav1enc1` 1.4.1+dfsg-1 | `libSvtAv1Enc.so.1` | BSD-3-Clause-Clear | `libsvtav1enc1.copyright.txt` |
| `libswresample4` 7:5.1.9-0+deb12u1 | `libswresample.so.4` | LGPL-2.1+ | `libswresample4.copyright.txt` |
| `libswscale6` 7:5.1.9-0+deb12u1 | `libswscale.so.6` | LGPL-2.1+ | `libswscale6.copyright.txt` |
| `libtasn1-6` 4.19.0-2+deb12u1 | `libtasn1.so.6` | see the file | `libtasn1-6.copyright.txt` |
| `libthai0` 0.1.29-1 | `libthai.so.0` | LGPL-2.1+ | `libthai0.copyright.txt` |
| `libtheora0` 1.1.1+dfsg.1-16.1+deb12u1 | `libtheoradec.so.1`, `libtheoraenc.so.1` | BSD-3-Clause | `libtheora0.copyright.txt` |
| `libtwolame0` 0.4.0-2 | `libtwolame.so.0` | LGPL-2+ | `libtwolame0.copyright.txt` |
| `libudfread0` 1.1.2-1 | `libudfread.so.0` | LGPL-2.1+ | `libudfread0.copyright.txt` |
| `libunistring2` 1.0-2 | `libunistring.so.2` | LGPL-3+ or GPL-2+ | `libunistring2.copyright.txt` |
| `libva-drm2` 2.17.0-1 | `libva-drm.so.2` | Expat | `libva-drm2.copyright.txt` |
| `libva-x11-2` 2.17.0-1 | `libva-x11.so.2` | Expat | `libva-x11-2.copyright.txt` |
| `libva2` 2.17.0-1 | `libva.so.2` | Expat | `libva2.copyright.txt` |
| `libvdpau1` 1.5-2 | `libvdpau.so.1` | Expat | `libvdpau1.copyright.txt` |
| `libvorbis0a` 1.3.7-1 | `libvorbis.so.0` | BSD-3-Clause | `libvorbis0a.copyright.txt` |
| `libvorbisenc2` 1.3.7-1 | `libvorbisenc.so.2` | BSD-3-Clause | `libvorbisenc2.copyright.txt` |
| `libvorbisfile3` 1.3.7-1 | `libvorbisfile.so.3` | BSD-3-Clause | `libvorbisfile3.copyright.txt` |
| `libvpx7` 1.12.0-1+deb12u5 | `libvpx.so.7` | BSD-3-Clause | `libvpx7.copyright.txt` |
| `libwebp7` 1.2.4-0.2+deb12u1 | `libwebp.so.7` | see the file | `libwebp7.copyright.txt` |
| `libwebpmux3` 1.2.4-0.2+deb12u1 | `libwebpmux.so.3` | see the file | `libwebpmux3.copyright.txt` |
| `libx11-6` 2:1.8.4-2+deb12u2 | `libX11.so.6` | see the file | `libx11-6.copyright.txt` |
| `libx11-xcb1` 2:1.8.4-2+deb12u2 | `libX11-xcb.so.1` | see the file | `libx11-xcb1.copyright.txt` |
| `libx264-164` 2:0.164.3095+gitbaee400-3 | `libx264.so.164` | GPL-2+ | `libx264-164.copyright.txt` |
| `libx265-199` 3.5-2+b1 | `libx265.so.199` | GPL-2+ | `libx265-199.copyright.txt` |
| `libxau6` 1:1.0.9-1 | `libXau.so.6` | see the file | `libxau6.copyright.txt` |
| `libxcb-dri3-0` 1.15-1 | `libxcb-dri3.so.0` | see the file | `libxcb-dri3-0.copyright.txt` |
| `libxcb-render0` 1.15-1 | `libxcb-render.so.0` | see the file | `libxcb-render0.copyright.txt` |
| `libxcb-shm0` 1.15-1 | `libxcb-shm.so.0` | see the file | `libxcb-shm0.copyright.txt` |
| `libxcb1` 1.15-1 | `libxcb.so.1` | see the file | `libxcb1.copyright.txt` |
| `libxdmcp6` 1:1.1.2-3 | `libXdmcp.so.6` | see the file | `libxdmcp6.copyright.txt` |
| `libxext6` 2:1.3.4-1+b1 | `libXext.so.6` | see the file | `libxext6.copyright.txt` |
| `libxfixes3` 1:6.0.0-2 | `libXfixes.so.3` | see the file | `libxfixes3.copyright.txt` |
| `libxml2` 2.9.14+dfsg-1.3~deb12u6 | `libxml2.so.2` | MIT-1 | `libxml2.copyright.txt` |
| `libxrender1` 1:0.9.10-1.1 | `libXrender.so.1` | see the file | `libxrender1.copyright.txt` |
| `libxvidcore4` 2:1.3.7-1 | `libxvidcore.so.4` | GPL-2+ | `libxvidcore4.copyright.txt` |
| `libzmq5` 4.3.4-6 | `libzmq.so.5` | LGPL-3.0+ with special exception granted by copyright holders | `libzmq5.copyright.txt` |
| `libzvbi0` 0.2.41-1+deb12u1 | `libzvbi.so.0` | GPL-2+ | `libzvbi0.copyright.txt` |
| `ocl-icd-libopencl1` 2.3.1-1 | `libOpenCL.so.1` | BSD-2-Clause | `ocl-icd-libopencl1.copyright.txt` |

The game itself is not included in `gtalcs-psp.zip`: its files come from your own copy.
