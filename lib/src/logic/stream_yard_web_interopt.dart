class StreamYardWebInteropt {
  static StreamYardWebInteropt get instance => StreamYardWebInteropt.create();

  StreamYardWebInteropt._();
  StreamYardWebInteropt.create() : this._();

  String streamUrl(String streamId) => 'https://streamyard.com/watch/$streamId';
}
