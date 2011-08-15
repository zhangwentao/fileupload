package com.renren.fileupload 
{
	import com.renren.picUpload.events.DBUploaderEvent;
	import com.renren.util.net.ByteArrayUploader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.EventDispatcher;
	
	/**
	 * 上传 DataBlock 至服务器
	 * @author taowenzhang@gmail.com
	 */
	class DataBlockUploader extends EventDispatcher
	{
		public static var upload_url:String = "http://upload.renren.com/upload.fcgi?pagetype=addflash&hostid=200208111";
		
		private var uploader:ByteArrayUploader;		
		private var dataBlock:DataBlock;//上传的数据块
		
		public var response:*;
			
		private function initUploader():void
		{
			uploader= new ByteArrayUploader();//用于上传二进制数据
			uploader.url = upload_url;		  //上传cgiurl
			uploader.addEventListener(IOErrorEvent.IO_ERROR, handle_ioError);
			uploader.addEventListener(Event.COMPLETE, handle_upload_complete);
		}
		
		/**
		 * 上传dataBlock
		 * @param	dataBlock 
		 */
		public function upload(dataBlock:DataBlock):void
		{
			initUploader();
			this.dataBlock = dataBlock;
			dataBlock.file.status = FileItem.FILE_STATUS_IN_PROGRESS;//设置图片状态为:正在上传
			var urlVar:Object = uploader.urlVariables;
			urlVar["block_index"] = dataBlock.index;
			urlVar["block_count"] = dataBlock.count;
			urlVar["uploadid"] = dataBlock.file.id;
			uploader.upLoad(dataBlock.data);
		}
		
		
		/**
		 * 处理ioError
		 * @param	evt		<ioErrorEvent>	
		 */
		private function handle_ioError(evt:IOErrorEvent):void
		{
			dispatchEvent(evt);
		}
		
		/**
		 * 上传完毕服务器返回数据后调用
		 * @param	evt		<Event>
		 */
		private function handle_upload_complete(evt:Event):void
		{
			response = evt.target.data;
			var event:DBUploaderEvent = new DBUploaderEvent(DBUploaderEvent.COMPLETE);
			event.dataBlock = dataBlock;
			dispatchEvent(event);
			
			dataBlock.dispose();//释放内存
		}
	}
}