package com.renren.picupload 
{
	import com.renren.picUpload.events.DBUploaderEvent;
	import com.renren.picUpload.DataSlicer;
	import com.renren.util.CirularQueue;
	import com.renren.util.net.SimpleURLLoader;
	import com.renren.util.ObjectPool;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import com.renren.picUpload.events.ThumbMakerEvent;
	import com.renren.util.img.ExifInjector;
	import com.renren.picUpload.events.PicUploadEvent;
	import flash.external.ExternalInterface;
	import flash.events.IOErrorEvent;
	
	/**
	 * 缩略图绘制完毕事件
	 */
	[Event(name = ThumbMakerEvent.THUMB_MAKED, type = "ThumbMakerEvent")]
	
	/**
	 * 图片上传成功事件
	 */
	[Event(name = PicUploadEvent.UPLOAD_SUCCESS, type = "PicUploadEvent")]
	
	/**
	 * 缩略图制作中
	 */
	[Event(name = ThumbMakerEvent.THUMB_MAKE_PROGRESS, type = "ThumbMakerEvent")]
	
	/**
	 * 上传主程序
	 * @author taowenzhang@gmail.com 
	 */
	public class PicUploader extends EventDispatcher
	{
		public var dataBlockNumLimit:uint = 50;			//DataBlock对象的数量上限值
		public var dataBlockSizeLimit:uint = 20480;  	//文件切片大小的上限单位字节
		public var uploaderPoolSize:uint = 40;			//DBUploader对象池容量(uploader总数量)
		public var picUploadNumOnce:uint = 100;     	//一次可以上传的照片数量
		public var DBQCheckInterval:Number = 500;		//dataBlock队列检查间隔
		public var UPCheckInterval:Number = 100;		//uploader对象池检查间隔
		
		private var fileItemQueue:CirularQueue;			//用户选择的文件的File队列
		private var DBqueue:Array;						//DataBlock队列
		private var uploaderPool:ObjectPool;			//DataBlockUploader对象池
		private var lock:Boolean;						//加载本地文件到内存锁(目的:逐个加载本地文件,一个加载完,才能加载下一个)
		private var UPMonitorTimer:Timer;				//uploader对象池监控timer
		private var DBQMonitorTimer:Timer;				//DataBlock队列监控timer
		private var fileItemQueuedNum:uint = 0;     	//已加入上传队列的FileItem数量
		private var curProcessFile:FileItem;			//当前从本地加载的图片文件
		private var curProcessFileExif:ByteArray;		//当前处理的文件的EXIF信息
		
		
		/**
		 * 构造函数
		 */
		public function PicUploader() 
		{
			
		}
		
		/**
		 * 初始化
		 */
		public function init():void
		{
			DataSlicer.block_size_limit = dataBlockSizeLimit;//设置文件切片上限
			DBqueue = new Array();//TODO:应该是一个不限长度的队列,因为这里存在一种'超支'的情况。
			fileItemQueue = new CirularQueue(picUploadNumOnce);
			DBQMonitorTimer = new Timer(DBQCheckInterval);
			UPMonitorTimer = new Timer(UPCheckInterval);
			DBQMonitorTimer.addEventListener(TimerEvent.TIMER, function() { DBQueueMonitor(); } );
			UPMonitorTimer.addEventListener(TimerEvent.TIMER, function() { uploaderPoolMonitor(); } );
			initUploaderPoll();
		}
		
		/**
		 * 初始化uploader对象池
		 * 1.创建对象池对象，并以 DBUploader对象填充
		 */
		private function initUploaderPoll():void
		{
			uploaderPool = new ObjectPool(uploaderPoolSize);
			for (var i:int = 0; i < uploaderPool.size; i++)
			{
				uploaderPool.put(new DBUploader());
			}
		}
		
		/**
		 * 启动上传进程
		 */
		public function start():void
		{
			DBQMonitorTimer.start();
			UPMonitorTimer.start();
			log("开启上传进程");
		}
		
		/**
		 * 关闭上传进程
		 */
		public function stop():void
		{
			DBQMonitorTimer.stop();
			UPMonitorTimer.stop();
			log("关闭上传进程");
		}
		
		/**
		 * 添加FileItem对象
		 * @param	fileItem	<FileItem>	
		 */
		public function addFileItem(fileItem:FileItem):void
		{
			if(fileItemQueuedNum < picUploadNumOnce)
			{
				fileItemQueue.enQueue(fileItem);   
				fileItem.status = FileItem.FILE_STATUS_QUEUED;//修改文件状态为:已加入上传队列
				fileItemQueuedNum++;
				log("[" + fileItem.fileReference.name + "]加入上传队列");
			}
			else
			{
				log("超过了一次可上传的最大数量:"+picUploadNumOnce);
			}
			log("fileQueuelength:"+fileItemQueue.count)
		}
	    
		
		
		public function cancelFile(fileId:String):void
		{
			
			var arr:Array = fileItemQueue.toArray();
			
			for each(var file:FileItem in arr)
			{
				if (file.id == fileId)
				{
					file.status = FileItem.FILE_STATUS_CANCELLED;
					var event:PicUploadEvent = new PicUploadEvent(PicUploadEvent.UPLOAD_CANCELED, file);
					dispatchEvent(event);
					break;
				}
			}
			
		    
		}
		
		/**
		 * 监控DBuploader对象池:
		 * TODO:1.有空闲DBuploader时，从DataBlock对象队列中取对象上传。
		 */
		private function uploaderPoolMonitor():void
		{
			
			log("!!!Uploader空闲数量:"+uploaderPool.length,"***上传缓冲区长度:"+DBqueue.length);
			if (uploaderPool.isEmpty || !DBqueue.length)
			{
				/*如果没有空闲的DBUploader对象或者没有需要上传的数据块，就什么都不做*/
				return;
			}
			
			/*用一个uploader上传一个dataBlock*/
			var uploader:DBUploader = uploaderPool.fetch() as DBUploader;
			var dataBlock:DataBlock = DBqueue.shift() as DataBlock;
			log("***上传缓冲区长度:"+DBqueue.length);
			log("开始上传 [" + dataBlock.file.fileReference.name + "] 的第" + dataBlock.index + "块数据");
			uploader.addEventListener(DBUploaderEvent.COMPLETE, handle_dataBlock_uploaded);
            uploader.addEventListener(IOErrorEvent.IO_ERROR, handle_IOError);
			dispatchEvent(new PicUploadEvent(PicUploadEvent.UPLOAD_PROGRESS,dataBlock.file));
			uploader.upload(dataBlock);
		}
		
		
		/**
		 * 监控DBQueue队列：
		 * TODO:1.如果为上传的DataBlock对象数量小于上限，就去从用户选择的文件中加载文件.
		 */
		private function DBQueueMonitor():void
		{
			if (DBqueue.length >= dataBlockNumLimit || fileItemQueue.isEmpty || lock)
			{
				/*如果DBQueue中的DataBlock数量大于等于的上限或者。。就什么都不做*/
				return;
			}
			
			curProcessFile = fileItemQueue.deQueue();
			while (curProcessFile.status == FileItem.FILE_STATUS_CANCELLED)
			{
				curProcessFile = fileItemQueue.deQueue();
			}
			curProcessFile.fileReference.addEventListener(Event.COMPLETE, handle_fileData_loaded);
			lock = true;//上锁
			curProcessFile.fileReference.load();
			log("!!!上传缓冲区有空间,开始加载上传队列中的文件!!!DBQueue.length:"+DBqueue.length);
		}
		
		
		/**
		 * 处理本地文件加载完毕。
		 * TODO:1.压缩图片
		 * TODO:2.生成缩略图
		 * TODO:3.文件分块，放入DataBlock队列
		 * @param	evt
		 */
		private function handle_fileData_loaded(evt:Event):void
		{
			log("[" + curProcessFile.fileReference.name + "]加载到内存");
			var fileData:ByteArray = evt.target.data as ByteArray;//从本地加载的图片数据
			var temp:ByteArray = new ByteArray();
			
		}
		
		
		
		
		/**
		 * DBUploader成功上传数据完毕后执行:
		 * TODO:1.把成功上传后的DBUploader对象放回DBUploader对象池。
		 * TODO:2.
		 * @param	evt	<DBUploaderEvent>
		 */
		private function handle_dataBlock_uploaded(evt:DBUploaderEvent):void
		{
			
		}
	}

}