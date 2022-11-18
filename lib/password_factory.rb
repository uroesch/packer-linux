class PasswordFactory
  SALT_LENGTH    = 13
  PW_LENGTH      = 12
  SALT_CHARS     = (0..9).to_a + ('a'..'z').to_a + ('A'..'Z').to_a
  PW_CHARS       = SALT_CHARS
  PREFIX_DEFAULT = '$6$'
  PREFIX         = {
    sha512:   '$6$',
    sha256:   '$5$',
    blowfish: '$2a$',
    md5:      '$1$',
    des:      ''
  }

  def initialize(pw_type = 'sha512', password = nil)
    @pw_type  = pw_type
    @pw_hash  = nil
    @password = password
    prefix
    create_salt
    create_password
    crypt_password
  end

  def plain
    @password
  end

  def hashed
    @pw_hash
  end

  # allowd methods defind in PREFIX
  def self.method_missing(method, *args, &block)
    begin
      raise "Hash method '#{method}' not supported" \
        unless PREFIX.fetch(method, false)
      new(method, args[0])
    rescue => e
      puts e.message
      exit 1
    end
  end

  private
  def crypt_password
    begin
      @pw_hash = @password.crypt(@pw_prefix + @salt)
    rescue => e
      $stderr.puts "Cannot create a #@pw_type hash - #{e.message}"
      exit 1
    end
  end

  def prefix
    @pw_prefix = PREFIX.fetch(@pw_type.to_sym, PREFIX_DEFAULT)
  end

  def create_password(pw_length = PW_LENGTH, special_chars = [])
    return unless @password.nil?
    pw_chars = PW_CHARS + special_chars
    @password = (0..pw_length).map do
      pw_chars[rand(pw_chars.length - 1)]
    end.join
  end

  def create_salt
    @salt = (0..SALT_LENGTH).map do
      SALT_CHARS[rand (SALT_CHARS.length - 1)]
    end.join
  end
end
