�YU��.����X]á���X��WSOCKDRVR	 ����WVQP��ώǿ�.���F<Ar<Zw &:u	GI�u����� XY^_�= t= t
���r����r��f.�>� t.�����t��=�u ��'t��>t��ώǿ`���ώǿ����.���                   wsock.vxd 
                                                                                                       ��������X r���3�.������.��G.�E�E�	�!3ۊـ�.��G.�E�E�	�!��b�!�۾� �<u� < u.�� .�� ��<Ar<Zw .�>� u7.�>� u<-t
</t<?t �!.���<ft
<ht<?t
�o.����.��.�&���t��t��t��t�D<0u@.�� �p�<xu3�i�<0r,<fw(<as<9v�,�,0.�&���������
�.�&��<����ÌȎ؎���м?����.��.�&����	�!���	�!��s
�l�	�!�.�>� t�.�>� u"�33��!<�t��r��2u�
���	�!�� .��`�5.���!���t&�����.�#�u�W�	�!�[��B�	�!� .��.�>�ow�.��<gt{<`rw<ows.����r|��	�!�&�	�!���B�	�!���' �/.�>�.���5�/�!.��.���%�/���!�%.����!�J�@��C�!�1�@��B� �!����	�!����	�!����	�!���	�!�L�!WSOCKVDD 1.1
$Copyright (c) 1999 B�rczi G�bor
$failed to initialize the VDD
$VDD successfully loaded.
$Using software interrupt 0x$
$?$0123456789ABCDEFWSOCKVDD already installed at interrupt 0x$Run this program in a DOS box under Windows NT!
$Program not loaded.
$
Usage: WSOCKVDD [options] [intno]
   -h -- display this help screen
   -f -- Force to load TSR (even if WinNT is not detected)

Example: WSOCKVDD -f 0x60
$Invalid parameter specified
$Invalid interrupt number specified
$wsockvdd.dll VDDRegisterInit VDDDispatch   e  