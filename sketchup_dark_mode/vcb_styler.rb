# frozen_string_literal: true

require 'fiddle'

module SketchupDarkMode
  module VcbStyler
    extend self

    PATTERN = "\x80\x7F\x40\x00\x74\x11\xBA\x03\x00\x00\x00".b
    PAGE_EXECUTE_READWRITE = 0x40

    @patch_addr = nil
    @original_byte = nil
    @dark_vcb_active = false

    def find_patch_address
      return @patch_addr if @patch_addr

      kernel32 = Fiddle.dlopen('kernel32.dll')
      fn_get_handle = Fiddle::Function.new(kernel32['GetModuleHandleW'], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP)
      base = fn_get_handle.call(0)
      return nil if base.nil? || base.to_i == 0

      # Read DOS & NT headers to find .text section
      dos_magic = base[0, 2].unpack1('S<')
      return nil unless dos_magic == 0x5A4D # 'MZ'

      lfanew = base[0x3C, 4].unpack1('L<')
      nt_sig = base[lfanew, 4].unpack1('L<')
      return nil unless nt_sig == 0x4550 # 'PE\0\0'

      num_sections = base[lfanew + 6, 2].unpack1('S<')
      opt_hdr_size = base[lfanew + 20, 2].unpack1('S<')
      sec_table_offset = lfanew + 24 + opt_hdr_size

      text_base = nil
      text_size = nil

      num_sections.times do |i|
        sec_offset = sec_table_offset + i * 40
        sec_name = base[sec_offset, 8].strip
        vsize = base[sec_offset + 8, 4].unpack1('L<')
        vaddr = base[sec_offset + 12, 4].unpack1('L<')
        if sec_name.start_with?('.text')
          text_base = base.to_i + vaddr
          text_size = vsize
          break
        end
      end

      return nil unless text_base && text_size

      # Search for PATTERN in .text section
      chunk_size = 65536
      overlap = PATTERN.bytesize
      offset = 0

      while offset < text_size
        read_len = [chunk_size + overlap, text_size - offset].min
        ptr = Fiddle::Pointer.new(text_base + offset)
        bytes = ptr[0, read_len]
        idx = bytes.index(PATTERN)
        if idx
          target = text_base + offset + idx + 4 # points to 0x74
          @patch_addr = target
          @original_byte = 0x74
          Logger.info("[VcbStyler] Found StatusVCBEdit white-suppress target at 0x#{@patch_addr.to_s(16)}") if defined?(Logger)
          return @patch_addr
        end
        offset += chunk_size
      end

      Logger.warn('[VcbStyler] StatusVCBEdit pattern not found in .text section.') if defined?(Logger)
      nil
    rescue StandardError => e
      Logger.error('[VcbStyler] Error locating StatusVCBEdit patch address', e) if defined?(Logger)
      nil
    end

    def apply_dark_vcb(enable)
      addr = find_patch_address
      return false unless addr

      kernel32 = Fiddle.dlopen('kernel32.dll')
      fn_protect = Fiddle::Function.new(
        kernel32['VirtualProtect'],
        [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP],
        Fiddle::TYPE_INT
      )

      old_prot = Fiddle::Pointer.malloc(8)
      ptr = Fiddle::Pointer.new(addr)

      desired_byte = enable ? 0xEB : 0x74 # 0xEB = unconditional jmp (dark), 0x74 = je (stock)
      current_byte = ptr[0, 1].ord

      if current_byte != desired_byte
        ret = fn_protect.call(ptr, 1, PAGE_EXECUTE_READWRITE, old_prot)
        return false if ret == 0

        ptr[0] = desired_byte

        orig_prot = old_prot[0, 4].unpack1('L<')
        fn_protect.call(ptr, 1, orig_prot, old_prot)
      end

      @dark_vcb_active = enable
      Logger.info("[VcbStyler] StatusVCBEdit byte set to #{enable ? '0xEB (DARK)' : '0x74 (STOCK)'}") if defined?(Logger)
      true
    rescue StandardError => e
      Logger.error('[VcbStyler] Error applying VCB patch', e) if defined?(Logger)
      false
    end

    def dark_vcb_active?
      @dark_vcb_active
    end
  end
end
